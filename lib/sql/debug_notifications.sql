-- Debug query to see notification data structure
-- Run this to see how notifications are being stored

SELECT 
  id,
  user_id,
  type,
  title,
  message,
  data,
  created_at,
  is_read
FROM notifications 
WHERE type = 'match_invitation' 
ORDER BY created_at DESC 
LIMIT 5;
