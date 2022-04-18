save_feedback = """INSERT INTO feedback (
    query, item_id, sort_order, msg, type_of_feedback
) VALUES (%s, %s, %s, %s, %s);"""
