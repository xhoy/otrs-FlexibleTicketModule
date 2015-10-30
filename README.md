# otrs-FlexibleTicketModule

Add to database:
- INSERT INTO article_type (name, comments, valid_id, create_time, create_by, change_time, change_by) VALUES ('visit', 'All tickets for visits', 1, now(), 1, now(), 1)
- INSERT INTO ticket_history_type (name, comments, valid_id, create_time, create_by, change_time, change_by) VALUES ('VisitAtCustomer', 'We visted customer on site', 1, now(), 1, now(), 1)
- INSERT INTO ticket_history_type (name, comments, valid_id, create_time, create_by, change_time, change_by) VALUES ('VisitAtAgent', 'Customer Visted Agent (at location agent) ', 1, now(), 1, now(), 1)

change ticket System::Permission in sysconfig:
- add visit
