-- [243-8] 同じソースで作った二つのトークンのランタイムコード: 長さと違うバイトの数
select a.name as a, b.name as b, varbinary_length(a.code) as len_a, varbinary_length(b.code) as len_b, a.code = b.code as same
from anvil.code_now a, anvil.code_now b where a.name = 'TKA' and b.name = 'FEE';
