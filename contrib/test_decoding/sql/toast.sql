-- predictability
SET synchronous_commit = on;

DROP TABLE IF EXISTS xpto;

SELECT 'init' FROM pg_create_logical_replication_slot('regression_slot', 'test_decoding');

CREATE SEQUENCE xpto_rand_seq START 79 INCREMENT 1499; -- portable "random"
CREATE TABLE xpto (
    id serial primary key,
    toasted_col1 text,
    rand1 float8 DEFAULT nextval('xpto_rand_seq'),
    toasted_col2 text,
    rand2 float8 DEFAULT nextval('xpto_rand_seq')
);

-- uncompressed external toast data
INSERT INTO xpto (toasted_col1, toasted_col2) SELECT string_agg(g.i::text, ''), string_agg((g.i*2)::text, '') FROM generate_series(1, 2000) g(i);

-- compressed external toast data
INSERT INTO xpto (toasted_col2) SELECT repeat(string_agg(to_char(g.i, 'FM0000'), ''), 50) FROM generate_series(1, 500) g(i);

-- update of existing column
UPDATE xpto SET toasted_col1 = (SELECT string_agg(g.i::text, '') FROM generate_series(1, 2000) g(i)) WHERE id = 1;

UPDATE xpto SET rand1 = 123.456 WHERE id = 1;

-- updating external via INSERT ... ON CONFLICT DO UPDATE
INSERT INTO xpto(id, toasted_col2) VALUES (2, 'toasted2-upsert')
ON CONFLICT (id)
DO UPDATE SET toasted_col2 = EXCLUDED.toasted_col2 || xpto.toasted_col2;

DELETE FROM xpto WHERE id = 1;

DROP TABLE IF EXISTS toasted_key;
CREATE TABLE toasted_key (
    id serial,
    toasted_key text PRIMARY KEY,
    toasted_col1 text,
    toasted_col2 text
);

ALTER TABLE toasted_key ALTER COLUMN toasted_key SET STORAGE EXTERNAL;
ALTER TABLE toasted_key ALTER COLUMN toasted_col1 SET STORAGE EXTERNAL;

INSERT INTO toasted_key(toasted_key, toasted_col1) VALUES(repeat('1234567890', 200), repeat('9876543210', 200));

-- test update of a toasted key without changing it
UPDATE toasted_key SET toasted_col2 = toasted_col1;
-- test update of a toasted key, changing it
UPDATE toasted_key SET toasted_key = toasted_key || '1';

DELETE FROM toasted_key;

-- Test that HEAP2_MULTI_INSERT insertions with and without toasted
-- columns are handled correctly
CREATE TABLE toasted_copy (
    id int primary key, -- no default, copy didn't use to handle that with multi inserts
    data text
);
ALTER TABLE toasted_copy ALTER COLUMN data SET STORAGE EXTERNAL;
\copy toasted_copy FROM STDIN
1	untoasted1
2	toasted1-12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
3	untoasted2
4	toasted2-12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
5	untoasted3
6	untoasted4
7	untoasted5
8	untoasted6
9	untoasted7
10	untoasted8
11	untoasted9
12	untoasted10
13	untoasted11
14	untoasted12
15	untoasted13
16	untoasted14
17	untoasted15
18	untoasted16
19	untoasted17
20	untoasted18
21	untoasted19
22	untoasted20
23	untoasted21
24	untoasted22
25	untoasted23
26	untoasted24
27	untoasted25
28	untoasted26
29	untoasted27
30	untoasted28
31	untoasted29
32	untoasted30
33	untoasted31
34	untoasted32
35	untoasted33
36	untoasted34
37	untoasted35
38	untoasted36
39	untoasted37
40	untoasted38
41	untoasted39
42	untoasted40
43	untoasted41
44	untoasted42
45	untoasted43
46	untoasted44
47	untoasted45
48	untoasted46
49	untoasted47
50	untoasted48
51	untoasted49
52	untoasted50
53	untoasted51
54	untoasted52
55	untoasted53
56	untoasted54
57	untoasted55
58	untoasted56
59	untoasted57
60	untoasted58
61	untoasted59
62	untoasted60
63	untoasted61
64	untoasted62
65	untoasted63
66	untoasted64
67	untoasted65
68	untoasted66
69	untoasted67
70	untoasted68
71	untoasted69
72	untoasted70
73	untoasted71
74	untoasted72
75	untoasted73
76	untoasted74
77	untoasted75
78	untoasted76
79	untoasted77
80	untoasted78
81	untoasted79
82	untoasted80
83	untoasted81
84	untoasted82
85	untoasted83
86	untoasted84
87	untoasted85
88	untoasted86
89	untoasted87
90	untoasted88
91	untoasted89
92	untoasted90
93	untoasted91
94	untoasted92
95	untoasted93
96	untoasted94
97	untoasted95
98	untoasted96
99	untoasted97
100	untoasted98
101	untoasted99
102	untoasted100
103	untoasted101
104	untoasted102
105	untoasted103
106	untoasted104
107	untoasted105
108	untoasted106
109	untoasted107
110	untoasted108
111	untoasted109
112	untoasted110
113	untoasted111
114	untoasted112
115	untoasted113
116	untoasted114
117	untoasted115
118	untoasted116
119	untoasted117
120	untoasted118
121	untoasted119
122	untoasted120
123	untoasted121
124	untoasted122
125	untoasted123
126	untoasted124
127	untoasted125
128	untoasted126
129	untoasted127
130	untoasted128
131	untoasted129
132	untoasted130
133	untoasted131
134	untoasted132
135	untoasted133
136	untoasted134
137	untoasted135
138	untoasted136
139	untoasted137
140	untoasted138
141	untoasted139
142	untoasted140
143	untoasted141
144	untoasted142
145	untoasted143
146	untoasted144
147	untoasted145
148	untoasted146
149	untoasted147
150	untoasted148
151	untoasted149
152	untoasted150
153	untoasted151
154	untoasted152
155	untoasted153
156	untoasted154
157	untoasted155
158	untoasted156
159	untoasted157
160	untoasted158
161	untoasted159
162	untoasted160
163	untoasted161
164	untoasted162
165	untoasted163
166	untoasted164
167	untoasted165
168	untoasted166
169	untoasted167
170	untoasted168
171	untoasted169
172	untoasted170
173	untoasted171
174	untoasted172
175	untoasted173
176	untoasted174
177	untoasted175
178	untoasted176
179	untoasted177
180	untoasted178
181	untoasted179
182	untoasted180
183	untoasted181
184	untoasted182
185	untoasted183
186	untoasted184
187	untoasted185
188	untoasted186
189	untoasted187
190	untoasted188
191	untoasted189
192	untoasted190
193	untoasted191
194	untoasted192
195	untoasted193
196	untoasted194
197	untoasted195
198	untoasted196
199	untoasted197
200	untoasted198
201	toasted3-12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
202	untoasted199
203	untoasted200
\.
SELECT substr(data, 1, 200) FROM pg_logical_slot_get_changes('regression_slot', NULL, NULL, 'include-xids', '0', 'skip-empty-xacts', '1');

-- test we can decode "old" tuples bigger than the max heap tuple size correctly
DROP TABLE IF EXISTS toasted_several;
CREATE TABLE toasted_several (
    id serial unique not null,
    toasted_key text primary key,
    toasted_col1 text,
    toasted_col2 text
);
ALTER TABLE toasted_several REPLICA IDENTITY FULL;
ALTER TABLE toasted_several ALTER COLUMN toasted_key SET STORAGE EXTERNAL;
ALTER TABLE toasted_several ALTER COLUMN toasted_col1 SET STORAGE EXTERNAL;
ALTER TABLE toasted_several ALTER COLUMN toasted_col2 SET STORAGE EXTERNAL;

-- Change the storage of the index back to EXTENDED, separately from
-- the table.  This is currently not doable via DDL, but it is
-- supported internally.
UPDATE pg_attribute SET attstorage = 'x' WHERE attrelid = 'toasted_several_pkey'::regclass AND attname = 'toasted_key';

INSERT INTO toasted_several(toasted_key) VALUES(repeat('9876543210', 10000));
SELECT pg_column_size(toasted_key) > 2^16 FROM toasted_several;

SELECT regexp_replace(data, '^(.{100}).*(.{100})$', '\1..\2') FROM pg_logical_slot_peek_changes('regression_slot', NULL, NULL, 'include-xids', '0', 'skip-empty-xacts', '1');

-- test update of a toasted key without changing it
UPDATE toasted_several SET toasted_col1 = toasted_key;
UPDATE toasted_several SET toasted_col2 = toasted_col1;

SELECT regexp_replace(data, '^(.{100}).*(.{100})$', '\1..\2') FROM pg_logical_slot_get_changes('regression_slot', NULL, NULL, 'include-xids', '0', 'skip-empty-xacts', '1');

/*
 * update with large tuplebuf, in a transaction large enough to force to spool to disk
 */
BEGIN;
INSERT INTO toasted_several(toasted_key) SELECT * FROM generate_series(1, 10234);
UPDATE toasted_several SET toasted_col1 = toasted_col2 WHERE id = 1;
DELETE FROM toasted_several WHERE id = 1;
COMMIT;

DROP TABLE toasted_several;

SELECT regexp_replace(data, '^(.{100}).*(.{100})$', '\1..\2') FROM pg_logical_slot_get_changes('regression_slot', NULL, NULL, 'include-xids', '0', 'skip-empty-xacts', '1')
WHERE data NOT LIKE '%INSERT: %';

/*
 * Test decoding relation rewrite with toast. The insert into tbl2 within the
 * same transaction is there to check that there is no remaining toast_hash not
 * being reset.
 */
CREATE TABLE tbl1 (a INT, b TEXT);
CREATE TABLE tbl2 (a INT);
ALTER TABLE tbl1 ALTER COLUMN b SET STORAGE EXTERNAL;
BEGIN;
INSERT INTO tbl1 VALUES(1, repeat('a', 4000)) ;
ALTER TABLE tbl1 ADD COLUMN id serial primary key;
INSERT INTO tbl2 VALUES(1);
commit;
SELECT substr(data, 1, 200) FROM pg_logical_slot_get_changes('regression_slot', NULL, NULL, 'include-xids', '0', 'skip-empty-xacts', '1');

SELECT pg_drop_replication_slot('regression_slot');
