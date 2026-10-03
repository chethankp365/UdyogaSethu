-- Migration 0180: Fix category names for plumbing, painting, delivery, cleaner, domestic_help, agri_labour, and loader
-- Fixes wrong-script characters in Telugu (te) and Tamil (ta) JSONB translations

UPDATE service_categories
SET names = jsonb_set(names, '{te}', '"ప్లంబింగ్"')
WHERE slug = 'plumbing';

UPDATE service_categories
SET names = jsonb_set(names, '{te}', '"పెయింటింగ్"')
WHERE slug = 'painting';

UPDATE service_categories
SET names = jsonb_set(names, '{te}', '"డెలివరీ"')
WHERE slug = 'delivery';

UPDATE service_categories
SET names = jsonb_set(names, '{te}', '"క్లీనర్"')
WHERE slug = 'cleaner';

UPDATE service_categories
SET names = jsonb_set(names, '{te}', '"ఇంటి పని"')
WHERE slug = 'domestic_help';

UPDATE service_categories
SET names = jsonb_set(names, '{te}', '"వ్యవసాయ కూలీ"')
WHERE slug = 'agri_labour';

UPDATE service_categories
SET names = jsonb_set(names, '{te}', '"లోడర్"')
WHERE slug = 'loader';

UPDATE service_categories
SET names = jsonb_set(names, '{ta}', '"சுமை தூக்குபவர்"')
WHERE slug = 'loader';

NOTIFY pgrst, 'reload schema';
