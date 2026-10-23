-- ============================================================================
-- SMART LIBRARY MANAGEMENT SYSTEM (SLMS) - BACKEND POSTGRESQL PROPOSAL
-- ============================================================================
-- Execution Instruction: Run this script in the Supabase SQL Editor as a Database Admin.
-- This script configures tables, RLS policies, indexes, transactional RPC functions,
-- and seeds the demo library with seats.
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. SCHEMA & TABLES
CREATE TABLE IF NOT EXISTS public.libraries (
    library_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.seats (
    seat_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    library_id UUID NOT NULL REFERENCES public.libraries(library_id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    floor_number INT NOT NULL DEFAULT 1,
    zone TEXT NOT NULL DEFAULT 'Main Hall',
    x_position DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    y_position DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    features TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_library_seat_label UNIQUE (library_id, label)
);

CREATE TABLE IF NOT EXISTS public.visits (
    visit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    library_id UUID NOT NULL REFERENCES public.libraries(library_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('inside', 'temporarily_away', 'completed')),
    entered_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    exited_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.bookings (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seat_id UUID NOT NULL REFERENCES public.seats(seat_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    library_id UUID NOT NULL REFERENCES public.libraries(library_id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('active', 'temporarily_away', 'completed', 'expired')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    grace_deadline TIMESTAMPTZ,
    released_at TIMESTAMPTZ
);

-- 3. INDEXES
CREATE INDEX IF NOT EXISTS idx_seats_library_id ON public.seats(library_id);
CREATE INDEX IF NOT EXISTS idx_visits_user_active ON public.visits(user_id, status) WHERE status IN ('inside', 'temporarily_away');
CREATE INDEX IF NOT EXISTS idx_bookings_seat_active ON public.bookings(seat_id, status) WHERE status IN ('active', 'temporarily_away');
CREATE INDEX IF NOT EXISTS idx_bookings_user_active ON public.bookings(user_id, status) WHERE status IN ('active', 'temporarily_away');

-- 4. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.libraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated read on libraries" ON public.libraries
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated read on seats" ON public.seats
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can view own visits" ON public.visits
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can view own bookings" ON public.bookings
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Prevent unauthorized direct inserts/updates/deletes on visits and bookings
-- All mutations must pass through the security-definer RPC functions below.


-- ============================================================================
-- 5. RPC BUSINESS OPERATIONS
-- ============================================================================

-- Function 1: get_seat_map
CREATE OR REPLACE FUNCTION public.get_seat_map(p_library_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_result JSONB;
BEGIN
    v_user_id := auth.uid();

    SELECT COALESCE(jsonb_agg(seat_data), '[]'::jsonb) INTO v_result
    FROM (
        SELECT 
            s.seat_id,
            s.label,
            s.floor_number,
            s.zone,
            s.x_position,
            s.y_position,
            s.features,
            CASE 
                WHEN b.user_id = v_user_id AND b.status IN ('active', 'temporarily_away') THEN 'mine'
                WHEN b.status = 'temporarily_away' THEN 'temporarily_away'
                WHEN b.status = 'active' THEN 'occupied'
                ELSE 'available'
            END AS availability_status,
            (b.user_id = v_user_id AND b.status IN ('active', 'temporarily_away')) AS is_mine,
            CASE 
                WHEN b.user_id = v_user_id THEN b.status 
                ELSE NULL 
            END AS my_booking_status,
            b.grace_deadline
        FROM public.seats s
        LEFT JOIN public.bookings b ON s.seat_id = b.seat_id 
            AND b.status IN ('active', 'temporarily_away')
            AND (b.grace_deadline IS NULL OR b.grace_deadline > timezone('utc'::text, now()))
        WHERE s.library_id = p_library_id
        ORDER BY s.floor_number ASC, s.label ASC
    ) seat_data;

    RETURN v_result;
END;
$$;

-- Function 2: get_my_state
CREATE OR REPLACE FUNCTION public.get_my_state(p_library_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_visit RECORD;
    v_booking RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Clean up expired grace bookings on query
    UPDATE public.bookings
    SET status = 'expired', released_at = timezone('utc'::text, now())
    WHERE user_id = v_user_id 
      AND status = 'temporarily_away' 
      AND grace_deadline <= timezone('utc'::text, now());

    -- Find active visit
    SELECT visit_id, status, entered_at INTO v_visit
    FROM public.visits
    WHERE user_id = v_user_id AND library_id = p_library_id AND status IN ('inside', 'temporarily_away')
    ORDER BY entered_at DESC LIMIT 1;

    -- Find active booking
    SELECT b.booking_id, b.seat_id, s.label AS seat_label, b.status, b.grace_deadline INTO v_booking
    FROM public.bookings b
    JOIN public.seats s ON b.seat_id = s.seat_id
    WHERE b.user_id = v_user_id AND b.library_id = p_library_id AND b.status IN ('active', 'temporarily_away')
    ORDER BY b.created_at DESC LIMIT 1;

    RETURN jsonb_build_object(
        'visit_id', v_visit.visit_id,
        'visit_status', v_visit.status,
        'entered_at', to_char(v_visit.entered_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'booking_id', v_booking.booking_id,
        'seat_id', v_booking.seat_id,
        'seat_label', v_booking.seat_label,
        'booking_status', v_booking.status,
        'grace_deadline', to_char(v_booking.grace_deadline, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
    );
END;
$$;

-- Function 3: scan_entry
CREATE OR REPLACE FUNCTION public.scan_entry(p_library_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_visit RECORD;
    v_booking RECORD;
    v_result TEXT;
    v_visit_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Check if active visit exists
    SELECT * INTO v_visit
    FROM public.visits
    WHERE user_id = v_user_id AND library_id = p_library_id AND status IN ('inside', 'temporarily_away')
    ORDER BY entered_at DESC LIMIT 1;

    -- Check if booking exists
    SELECT b.*, s.label AS seat_label INTO v_booking
    FROM public.bookings b
    JOIN public.seats s ON b.seat_id = s.seat_id
    WHERE b.user_id = v_user_id AND b.library_id = p_library_id AND b.status IN ('active', 'temporarily_away')
    ORDER BY b.created_at DESC LIMIT 1;

    IF v_visit.visit_id IS NOT NULL THEN
        IF v_visit.status = 'temporarily_away' THEN
            -- Check if grace period is still valid
            IF v_booking.grace_deadline IS NOT NULL AND v_booking.grace_deadline > timezone('utc'::text, now()) THEN
                -- Return within grace deadline: reinstate visit and seat
                UPDATE public.visits SET status = 'inside' WHERE visit_id = v_visit.visit_id;
                UPDATE public.bookings SET status = 'active', grace_deadline = NULL WHERE booking_id = v_booking.booking_id;
                v_result := 'returned';
            ELSE
                -- Grace period expired: expire seat, reinstate visit as inside
                UPDATE public.visits SET status = 'inside' WHERE visit_id = v_visit.visit_id;
                IF v_booking.booking_id IS NOT NULL THEN
                    UPDATE public.bookings SET status = 'expired', released_at = timezone('utc'::text, now()) WHERE booking_id = v_booking.booking_id;
                END IF;
                v_result := 'grace_expired_new_visit';
            END IF;
        ELSE
            v_result := 'already_inside';
        END IF;
        v_visit_id := v_visit.visit_id;
    ELSE
        -- Fresh new visit
        INSERT INTO public.visits (library_id, user_id, status, entered_at)
        VALUES (p_library_id, v_user_id, 'inside', timezone('utc'::text, now()))
        RETURNING visit_id INTO v_visit_id;
        v_result := 'entered';
    END IF;

    -- Return updated state
    RETURN (SELECT jsonb_build_object(
        'result', v_result,
        'visit_id', v_visit_id,
        'visit_status', 'inside',
        'entered_at', to_char(timezone('utc'::text, now()), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'booking_id', CASE WHEN v_result = 'returned' THEN v_booking.booking_id ELSE NULL END,
        'seat_id', CASE WHEN v_result = 'returned' THEN v_booking.seat_id ELSE NULL END,
        'seat_label', CASE WHEN v_result = 'returned' THEN v_booking.seat_label ELSE NULL END,
        'booking_status', CASE WHEN v_result = 'returned' THEN 'active' ELSE NULL END,
        'grace_deadline', NULL
    ));
END;
$$;

-- Function 4: book_seat
CREATE OR REPLACE FUNCTION public.book_seat(p_seat_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_seat RECORD;
    v_existing_booking RECORD;
    v_visit RECORD;
    v_new_booking_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Lock seat row to prevent concurrent race condition
    SELECT * INTO v_seat FROM public.seats WHERE seat_id = p_seat_id FOR UPDATE;
    IF v_seat.seat_id IS NULL THEN
        RAISE EXCEPTION 'SEAT_UNAVAILABLE';
    END IF;

    -- Verify user has an active visit inside the library
    SELECT * INTO v_visit FROM public.visits
    WHERE user_id = v_user_id AND library_id = v_seat.library_id AND status = 'inside'
    ORDER BY entered_at DESC LIMIT 1;

    IF v_visit.visit_id IS NULL THEN
        RAISE EXCEPTION 'NOT_INSIDE_LIBRARY';
    END IF;

    -- Check if user already holds an active or temporarily away seat
    SELECT * INTO v_existing_booking FROM public.bookings
    WHERE user_id = v_user_id AND library_id = v_seat.library_id AND status IN ('active', 'temporarily_away')
    LIMIT 1;

    IF v_existing_booking.booking_id IS NOT NULL THEN
        RAISE EXCEPTION 'ALREADY_HAS_SEAT';
    END IF;

    -- Check if target seat is already occupied or held in grace period
    IF EXISTS (
        SELECT 1 FROM public.bookings
        WHERE seat_id = p_seat_id 
          AND status IN ('active', 'temporarily_away')
          AND (grace_deadline IS NULL OR grace_deadline > timezone('utc'::text, now()))
    ) THEN
        RAISE EXCEPTION 'SEAT_UNAVAILABLE';
    END IF;

    -- Insert atomic booking
    INSERT INTO public.bookings (seat_id, user_id, library_id, status)
    VALUES (p_seat_id, v_user_id, v_seat.library_id, 'active')
    RETURNING booking_id INTO v_new_booking_id;

    RETURN jsonb_build_object(
        'booking_id', v_new_booking_id,
        'seat_id', v_seat.seat_id,
        'seat_label', v_seat.label,
        'booking_status', 'active',
        'created_at', to_char(timezone('utc'::text, now()), 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
    );
END;
$$;

-- Function 5: start_grace_period
CREATE OR REPLACE FUNCTION public.start_grace_period(p_library_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_booking RECORD;
    v_deadline TIMESTAMPTZ;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Find active booking
    SELECT * INTO v_booking
    FROM public.bookings
    WHERE user_id = v_user_id AND library_id = p_library_id AND status = 'active'
    FOR UPDATE;

    IF v_booking.booking_id IS NULL THEN
        RAISE EXCEPTION 'NO_ASSIGNED_SEAT';
    END IF;

    -- 20-minute authoritative server deadline
    v_deadline := timezone('utc'::text, now()) + INTERVAL '20 minutes';

    -- Transition booking and visit status to temporarily_away
    UPDATE public.bookings
    SET status = 'temporarily_away', grace_deadline = v_deadline
    WHERE booking_id = v_booking.booking_id;

    UPDATE public.visits
    SET status = 'temporarily_away'
    WHERE user_id = v_user_id AND library_id = p_library_id AND status = 'inside';

    RETURN jsonb_build_object(
        'booking_id', v_booking.booking_id,
        'seat_id', v_booking.seat_id,
        'booking_status', 'temporarily_away',
        'grace_deadline', to_char(v_deadline, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
    );
END;
$$;

-- Function 6: leave_library
CREATE OR REPLACE FUNCTION public.leave_library(p_library_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_visit RECORD;
    v_booking RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Complete active visits
    UPDATE public.visits
    SET status = 'completed', exited_at = timezone('utc'::text, now())
    WHERE user_id = v_user_id AND library_id = p_library_id AND status IN ('inside', 'temporarily_away')
    RETURNING * INTO v_visit;

    -- Release any active or grace bookings
    UPDATE public.bookings
    SET status = 'completed', released_at = timezone('utc'::text, now())
    WHERE user_id = v_user_id AND library_id = p_library_id AND status IN ('active', 'temporarily_away')
    RETURNING * INTO v_booking;

    RETURN jsonb_build_object(
        'result', 'left_library',
        'visit_status', 'completed',
        'booking_status', 'completed',
        'seat_id', v_booking.seat_id
    );
END;
$$;


-- ============================================================================
-- 6. DEMO SEED DATA
-- ============================================================================

-- Seed demo library with required UUID
INSERT INTO public.libraries (library_id, name)
VALUES ('11111111-1111-4111-8111-111111111111', 'Central Campus Demo Library')
ON CONFLICT (library_id) DO NOTHING;

-- Seed Floor 1 (Collaborative & Main Hall)
INSERT INTO public.seats (seat_id, library_id, label, floor_number, zone, x_position, y_position, features)
VALUES 
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'A1', 1, 'Main Hall', 1.0, 1.0, ARRAY['Power Outlet', 'Desk Lamp']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'A2', 1, 'Main Hall', 2.0, 1.0, ARRAY['Power Outlet']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'A3', 1, 'Main Hall', 3.0, 1.0, ARRAY['Desk Lamp']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'A4', 1, 'Main Hall', 4.0, 1.0, ARRAY['Power Outlet', 'Window View']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'B1', 1, 'Group Study', 1.0, 2.0, ARRAY['Whiteboard', 'Power Outlet']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'B2', 1, 'Group Study', 2.0, 2.0, ARRAY['Whiteboard']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'B3', 1, 'Group Study', 3.0, 2.0, ARRAY['Power Outlet']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'B4', 1, 'Group Study', 4.0, 2.0, ARRAY['Power Outlet', 'Window View'])
ON CONFLICT (library_id, label) DO NOTHING;

-- Seed Floor 2 (Quiet Study Zone)
INSERT INTO public.seats (seat_id, library_id, label, floor_number, zone, x_position, y_position, features)
VALUES 
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'Q1', 2, 'Quiet Zone', 1.0, 1.0, ARRAY['Quiet Zone', 'Power Outlet', 'Desk Lamp']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'Q2', 2, 'Quiet Zone', 2.0, 1.0, ARRAY['Quiet Zone', 'Power Outlet']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'Q3', 2, 'Quiet Zone', 3.0, 1.0, ARRAY['Quiet Zone', 'Window View', 'Power Outlet']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'Q4', 2, 'Quiet Zone', 4.0, 1.0, ARRAY['Quiet Zone', 'Desk Lamp']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'W1', 2, 'Window Bay', 1.0, 2.0, ARRAY['Window View', 'Power Outlet']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'W2', 2, 'Window Bay', 2.0, 2.0, ARRAY['Window View', 'Power Outlet']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'W3', 2, 'Window Bay', 3.0, 2.0, ARRAY['Window View']),
    (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'W4', 2, 'Window Bay', 4.0, 2.0, ARRAY['Window View', 'Quiet Zone'])
ON CONFLICT (library_id, label) DO NOTHING;
