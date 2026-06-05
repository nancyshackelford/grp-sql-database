UPDATE grp.data_dictionary
SET display_order = display_order - 1
WHERE table_name = 'import_project'
AND display_order > 5;