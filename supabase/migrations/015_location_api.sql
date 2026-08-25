-- RPC to fetch location hierarchy with bounding boxes
CREATE OR REPLACE FUNCTION get_locations(p_type TEXT, p_parent_id UUID DEFAULT NULL)
RETURNS TABLE (
  id UUID,
  name TEXT,
  parent_id UUID,
  bbox JSON
) AS $$
BEGIN
  IF p_type = 'country' THEN
    RETURN QUERY 
      SELECT c.id, c.name, NULL::UUID, ST_AsGeoJSON(ST_Envelope(c.geometry::geometry))::JSON
      FROM public.countries c
      ORDER BY c.name;
      
  ELSIF p_type = 'state' THEN
    RETURN QUERY 
      SELECT s.id, s.name, s.country_id, ST_AsGeoJSON(ST_Envelope(s.geometry::geometry))::JSON
      FROM public.states s
      WHERE (p_parent_id IS NULL OR s.country_id = p_parent_id)
      ORDER BY s.name;
      
  ELSIF p_type = 'district' THEN
    RETURN QUERY 
      SELECT d.id, d.name, d.state_id, ST_AsGeoJSON(ST_Envelope(d.geometry::geometry))::JSON
      FROM public.districts d
      WHERE (p_parent_id IS NULL OR d.state_id = p_parent_id)
      ORDER BY d.name;
      
  ELSIF p_type = 'municipality' THEN
    RETURN QUERY 
      SELECT m.id, m.name, m.district_id, ST_AsGeoJSON(ST_Envelope(m.geometry::geometry))::JSON
      FROM public.municipalities m
      WHERE (p_parent_id IS NULL OR m.district_id = p_parent_id)
      ORDER BY m.name;
      
  ELSE
    RAISE EXCEPTION 'Invalid location type: %', p_type;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
