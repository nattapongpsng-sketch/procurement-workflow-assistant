-- Audit events are append-only (Requirement FR-28): any UPDATE, DELETE or TRUNCATE fails.
CREATE OR REPLACE FUNCTION prevent_audit_event_changes()
RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_events is append-only: % is not allowed', TG_OP
    USING ERRCODE = 'insufficient_privilege';
END;
$$ LANGUAGE plpgsql;
