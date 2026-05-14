-- =====================================================
-- Change 001 dependency check
-- Purpose: identify views that mention treatment-related tables/fields
-- =====================================================

SELECT 
    schemaname,
    viewname
FROM pg_views
WHERE schemaname = 'grp'
AND definition ILIKE '%treatment%';
