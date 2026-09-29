-- ==============================================================================
-- THE ELITE FITNESS GYM - SUPABASE PRODUCTION DATABASE SCHEMA
-- ==============================================================================
-- Paste this entire script into your Supabase Dashboard:
-- Supabase Dashboard -> SQL Editor -> New Query -> Run.
-- ==============================================================================

-- 1. Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Gyms Table
CREATE TABLE IF NOT EXISTS gyms (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    owner_name TEXT,
    phone TEXT NOT NULL,
    email TEXT,
    website TEXT,
    address TEXT NOT NULL,
    city TEXT,
    logo_path TEXT,
    currency TEXT DEFAULT 'INR (₹)',
    upi_id TEXT,
    upi_payee_name TEXT,
    bank_account_holder TEXT,
    bank_account_number TEXT,
    bank_ifsc TEXT,
    bank_name TEXT,
    show_upi_qr_on_bill INTEGER DEFAULT 1,
    show_bank_details_on_bill INTEGER DEFAULT 1,
    default_print_format TEXT DEFAULT 'thermal_80mm',
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_gyms_phone ON gyms(phone);
CREATE INDEX IF NOT EXISTS idx_gyms_email ON gyms(email);

-- 3. Admins Table
CREATE TABLE IF NOT EXISTS admins (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    is_biometric_enabled INTEGER DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_admins_gym ON admins(gym_id);
CREATE INDEX IF NOT EXISTS idx_admins_phone ON admins(phone);

-- 4. Membership Packages Table
CREATE TABLE IF NOT EXISTS membership_packages (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text,
    deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_packages_gym ON membership_packages(gym_id);

-- 5. Membership Plans Table
CREATE TABLE IF NOT EXISTS membership_plans (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    package_id TEXT REFERENCES membership_packages(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    duration_days INTEGER NOT NULL,
    default_fee REAL NOT NULL,
    description TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_plans_gym ON membership_plans(gym_id);

-- 6. Trainers Table
CREATE TABLE IF NOT EXISTS trainers (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    role TEXT DEFAULT 'Trainer',
    specialization TEXT,
    monthly_salary REAL,
    photo_path TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text,
    deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_trainers_gym ON trainers(gym_id);

-- 7. Trainer Payouts Table
CREATE TABLE IF NOT EXISTS trainer_payouts (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    trainer_id TEXT REFERENCES trainers(id) ON DELETE CASCADE,
    amount REAL NOT NULL,
    payout_date TEXT NOT NULL,
    payout_type TEXT DEFAULT 'salary',
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text,
    deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_trainer_payouts_gym ON trainer_payouts(gym_id);

-- 8. Members Table
CREATE TABLE IF NOT EXISTS members (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    gender TEXT,
    date_of_birth TEXT,
    photo_path TEXT,
    notes TEXT,
    is_archived INTEGER DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text,
    deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_members_gym ON members(gym_id);
CREATE INDEX IF NOT EXISTS idx_members_phone ON members(phone);

-- 9. Memberships Table
CREATE TABLE IF NOT EXISTS memberships (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    member_id TEXT REFERENCES members(id) ON DELETE CASCADE,
    plan_id TEXT REFERENCES membership_plans(id),
    plan_name TEXT NOT NULL,
    package_id TEXT REFERENCES membership_packages(id) ON DELETE SET NULL,
    trainer_id TEXT REFERENCES trainers(id) ON DELETE SET NULL,
    personal_training_fee REAL DEFAULT 0,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    fee_amount REAL NOT NULL,
    status TEXT NOT NULL DEFAULT 'Active',
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_memberships_gym ON memberships(gym_id);
CREATE INDEX IF NOT EXISTS idx_memberships_member ON memberships(member_id);

-- 10. Audit Logs
CREATE TABLE IF NOT EXISTS membership_change_logs (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    member_id TEXT REFERENCES members(id) ON DELETE CASCADE,
    previous_membership_id TEXT,
    new_membership_id TEXT NOT NULL,
    previous_plan_name_snapshot TEXT,
    new_plan_name_snapshot TEXT NOT NULL,
    previous_fee_amount REAL,
    new_fee_amount REAL NOT NULL,
    reason TEXT,
    changed_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_mem_logs_gym ON membership_change_logs(gym_id);

CREATE TABLE IF NOT EXISTS trainer_change_logs (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    member_id TEXT REFERENCES members(id) ON DELETE CASCADE,
    membership_id TEXT,
    previous_trainer_id TEXT,
    previous_trainer_name_snapshot TEXT,
    new_trainer_id TEXT,
    new_trainer_name_snapshot TEXT,
    previous_personal_training_fee REAL DEFAULT 0,
    new_personal_training_fee REAL DEFAULT 0,
    reason TEXT,
    changed_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_trainer_logs_gym ON trainer_change_logs(gym_id);

-- 11. Bills Table
CREATE TABLE IF NOT EXISTS bills (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    bill_number TEXT NOT NULL UNIQUE,
    member_id TEXT REFERENCES members(id) ON DELETE CASCADE,
    member_name TEXT NOT NULL,
    member_phone TEXT NOT NULL,
    membership_id TEXT,
    plan_name TEXT NOT NULL,
    amount REAL NOT NULL,
    bill_date TEXT NOT NULL,
    due_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Pending',
    paid_amount REAL NOT NULL DEFAULT 0,
    payment_id TEXT,
    receipt_id TEXT,
    notes TEXT,
    is_auto_generated INTEGER DEFAULT 0,
    cycle_key TEXT,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_bills_gym ON bills(gym_id);

-- 12. Payments Table
CREATE TABLE IF NOT EXISTS payments (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    member_id TEXT REFERENCES members(id) ON DELETE CASCADE,
    membership_id TEXT,
    bill_id TEXT,
    amount REAL NOT NULL,
    payment_date TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    notes TEXT,
    receipt_id TEXT NOT NULL,
    receipt_number TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_payments_gym ON payments(gym_id);

-- 13. Receipts Table
CREATE TABLE IF NOT EXISTS receipts (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    payment_id TEXT NOT NULL,
    receipt_number TEXT NOT NULL UNIQUE,
    bill_number TEXT,
    member_name TEXT NOT NULL,
    member_phone TEXT NOT NULL,
    plan_name TEXT NOT NULL,
    trainer_name TEXT,
    personal_training_fee REAL DEFAULT 0,
    amount REAL NOT NULL,
    payment_method TEXT NOT NULL,
    payment_date TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    qr_payload TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_receipts_gym ON receipts(gym_id);

-- 14. Expenses Table
CREATE TABLE IF NOT EXISTS expenses (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Other',
    amount REAL NOT NULL,
    expense_date TEXT NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'Cash',
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_expenses_gym ON expenses(gym_id);

-- 15. Events Table
CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    location TEXT,
    trainer_id TEXT REFERENCES trainers(id) ON DELETE SET NULL,
    color_value BIGINT,
    created_at TEXT NOT NULL DEFAULT NOW()::text,
    updated_at TEXT NOT NULL DEFAULT NOW()::text,
    deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_events_gym ON events(gym_id);

-- 16. Announcements Table (With Supabase Realtime enabled)
CREATE TABLE IF NOT EXISTS announcements (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    title TEXT,
    message TEXT NOT NULL,
    image_path TEXT,
    category TEXT DEFAULT 'general',
    audience_type TEXT NOT NULL DEFAULT 'all',
    audience_label TEXT NOT NULL DEFAULT 'All Members',
    audience_plan_id TEXT,
    is_important INTEGER DEFAULT 0,
    is_pinned INTEGER DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'sent',
    scheduled_at TEXT,
    sent_at TEXT,
    created_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_announcements_gym ON announcements(gym_id);

-- Enable Realtime publication for announcements (so Client App gets instant updates)
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;

-- 17. Member Device Tokens Table (For Push Notifications)
CREATE TABLE IF NOT EXISTS member_device_tokens (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    gym_id TEXT REFERENCES gyms(id) ON DELETE CASCADE,
    member_id TEXT,
    fcm_token TEXT NOT NULL UNIQUE,
    platform TEXT DEFAULT 'android',
    last_active_at TEXT NOT NULL DEFAULT NOW()::text,
    created_at TEXT NOT NULL DEFAULT NOW()::text
);
CREATE INDEX IF NOT EXISTS idx_tokens_gym ON member_device_tokens(gym_id);

-- 18. Enable Row Level Security (RLS) with Permissive Default Access
-- Allows the app (using anon key) to read and sync tables.
DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'gyms', 'admins', 'membership_packages', 'membership_plans',
        'trainers', 'trainer_payouts', 'members', 'memberships',
        'membership_change_logs', 'trainer_change_logs', 'bills',
        'payments', 'receipts', 'expenses', 'events', 'announcements',
        'member_device_tokens'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', tbl);
        EXECUTE format('DROP POLICY IF EXISTS "Allow full anon access to %I" ON %I;', tbl, tbl);
        EXECUTE format('CREATE POLICY "Allow full anon access to %I" ON %I FOR ALL USING (true) WITH CHECK (true);', tbl, tbl);
    END LOOP;
END $$;

-- 19. Create Storage Buckets (Optional for photos/receipts)
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('member-photos', 'member-photos', true),
    ('gym-branding', 'gym-branding', true),
    ('announcements', 'announcements', true),
    ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Storage Access" ON storage.objects FOR ALL USING (true) WITH CHECK (true);
