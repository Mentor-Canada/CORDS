get_constrained_results_1 = """SELECT 2*asin(sqrt(pow(sin(radians({0}-geocoordinates[0])/2),2)
+cos(radians({0}))*cos(radians(geocoordinates[0]))*pow(sin(radians({1}-geocoordinates[1])/2), 2)))*6372.8 as distance, *
FROM resources
WHERE resource_agency_number in (
"""
get_constrained_results_2 = """)
AND 2*asin(sqrt(pow(sin(radians({0}-geocoordinates[0])/2),2)
+cos(radians({0}))*cos(radians(geocoordinates[0]))*pow(sin(radians({1}-geocoordinates[1])/2), 2)))*6372.8 < {2}"""

get_constrained_results_3 = """ORDER BY array_position(ARRAY[{0}]::varchar[], resource_agency_number)
LIMIT 50;
"""

get_cutoff_constrained_results_1 = """SELECT 2*asin(sqrt(pow(sin(radians({0}-geocoordinates[0])/2),2)
+cos(radians({0}))*cos(radians(geocoordinates[0]))*pow(sin(radians({1}-geocoordinates[1])/2), 2)))*6372.8 as distance, *
FROM resources
WHERE resource_agency_number in (
"""
get_cutoff_constrained_results_2 = """)
AND 2*asin(sqrt(pow(sin(radians({0}-geocoordinates[0])/2),2)
+cos(radians({0}))*cos(radians(geocoordinates[0]))*pow(sin(radians({1}-geocoordinates[1])/2), 2)))*6372.8 < {2} """

get_cutoff_constrained_results_3 = """ ORDER BY asin(sqrt(pow(sin(radians({0}-geocoordinates[0])/2),2)
+cos(radians({0}))*cos(radians(geocoordinates[0]))*pow(sin(radians({1}-geocoordinates[1])/2), 2)))
LIMIT 50;
"""
