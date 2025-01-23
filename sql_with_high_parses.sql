select inst_id, to_char(force_matching_signature) sig,count(exact_matching_signature) cnt
from (
 select inst_id, force_matching_signature, exact_matching_signature
 from gv$sql
 group by inst_id, force_matching_signature, exact_matching_signature )
 group by inst_id, force_matching_signature
 having count(exact_matching_signature) > 1
 order by cnt desc;

select * from gv$sql
where force_matching_signature='&1';
