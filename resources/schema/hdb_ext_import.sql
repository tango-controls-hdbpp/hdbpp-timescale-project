\c hdb

CREATE OR REPLACE FUNCTION expand_name() RETURNS TRIGGER AS $$
DECLARE
    len integer;
BEGIN
    IF (NEW.cs_name <> '' AND NEW.domain <> '' AND NEW.family <> '' AND NEW.member <> '' AND NEW.name <> '') IS NOT TRUE THEN
        len = (SELECT cardinality((SELECT regexp_split_to_array(NEW.att_name, E'/'))));
        NEW.name := (SELECT split_part(NEW.att_name, '/', len));
        NEW.member := (SELECT split_part(NEW.att_name, '/', len - 1));
        NEW.family := (SELECT split_part(NEW.att_name, '/', len - 2));
        NEW.domain := (SELECT split_part(NEW.att_name, '/', len - 3));
        NEW.cs_name := (SELECT split_part(NEW.att_name, '/', len - 4));
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER expand_name_trigger BEFORE INSERT ON att_conf FOR EACH ROW EXECUTE PROCEDURE expand_name();
