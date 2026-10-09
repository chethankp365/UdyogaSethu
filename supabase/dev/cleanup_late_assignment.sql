-- Teardown script for simulated late assignments

DELETE FROM public.jobs
WHERE title = 'Urgent Electrical Wiring - Simulated Late';
