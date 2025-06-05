-- Debug notification data structure for match invitations
-- Run this query to see what's actually being stored in the notifications table

SELECT 
  n.id,
  n.user_id,
  n.type,
  n.title,
  n.message,
  n.data,
  n.data->'invitation_id' as invitation_id_from_data,
  n.data->'match_id' as match_id_from_data,
  n.created_at
FROM notifications n 
WHERE n.type = 'match_invitation' 
ORDER BY n.created_at DESC 
LIMIT 10;

-- Also check match_invitations table to see what IDs exist
SELECT 
  id,
  match_id,
  inviter_id,
  invited_id,
  status,
  created_at
FROM match_invitations 
ORDER BY created_at DESC 
LIMIT 10;
