
get_item_by_id = """SELECT resource_description, description_francais, nom_publique, public_name, description_vector
FROM resources WHERE resource_agency_number = %s"""
