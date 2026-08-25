-- Add RPC for incrementing vote_count safely
CREATE OR REPLACE FUNCTION increment_vote(issue_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE issues
  SET vote_count = vote_count + 1
  WHERE id = issue_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
