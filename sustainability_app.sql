PGDMP  6    5                }            sustainability_app    17.2    17.2 $               0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false                       0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false                       0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false                       1262    17159    sustainability_app    DATABASE     �   CREATE DATABASE sustainability_app WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_South Africa.1252';
 "   DROP DATABASE sustainability_app;
                     postgres    false            �            1259    17174    admins    TABLE     �   CREATE TABLE public.admins (
    id integer NOT NULL,
    firstname character varying(100),
    lastname character varying(100),
    email character varying(150) NOT NULL,
    password text NOT NULL
);
    DROP TABLE public.admins;
       public         heap r       postgres    false            �            1259    17173    admins_id_seq    SEQUENCE     �   CREATE SEQUENCE public.admins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.admins_id_seq;
       public               postgres    false    220                       0    0    admins_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;
          public               postgres    false    219            �            1259    17185    questionnaire_responses    TABLE     �   CREATE TABLE public.questionnaire_responses (
    id integer NOT NULL,
    user_id integer,
    faculty text,
    year text,
    preference text,
    submitted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 +   DROP TABLE public.questionnaire_responses;
       public         heap r       postgres    false            �            1259    17184    questionnaire_responses_id_seq    SEQUENCE     �   CREATE SEQUENCE public.questionnaire_responses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.questionnaire_responses_id_seq;
       public               postgres    false    222                       0    0    questionnaire_responses_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.questionnaire_responses_id_seq OWNED BY public.questionnaire_responses.id;
          public               postgres    false    221            �            1259    17200    sdg_activity    TABLE     $  CREATE TABLE public.sdg_activity (
    id integer NOT NULL,
    user_id integer,
    sdg_id integer,
    action text,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT sdg_activity_action_check CHECK ((action = ANY (ARRAY['view'::text, 'play'::text])))
);
     DROP TABLE public.sdg_activity;
       public         heap r       postgres    false            �            1259    17199    sdg_activity_id_seq    SEQUENCE     �   CREATE SEQUENCE public.sdg_activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.sdg_activity_id_seq;
       public               postgres    false    224                       0    0    sdg_activity_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.sdg_activity_id_seq OWNED BY public.sdg_activity.id;
          public               postgres    false    223            �            1259    17163    users    TABLE     �   CREATE TABLE public.users (
    id integer NOT NULL,
    firstname character varying(100),
    lastname character varying(100),
    email character varying(150) NOT NULL,
    password text NOT NULL,
    active boolean DEFAULT true
);
    DROP TABLE public.users;
       public         heap r       postgres    false            �            1259    17162    users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.users_id_seq;
       public               postgres    false    218                       0    0    users_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
          public               postgres    false    217            h           2604    17177 	   admins id    DEFAULT     f   ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);
 8   ALTER TABLE public.admins ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    220    219    220            i           2604    17188    questionnaire_responses id    DEFAULT     �   ALTER TABLE ONLY public.questionnaire_responses ALTER COLUMN id SET DEFAULT nextval('public.questionnaire_responses_id_seq'::regclass);
 I   ALTER TABLE public.questionnaire_responses ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    221    222    222            k           2604    17203    sdg_activity id    DEFAULT     r   ALTER TABLE ONLY public.sdg_activity ALTER COLUMN id SET DEFAULT nextval('public.sdg_activity_id_seq'::regclass);
 >   ALTER TABLE public.sdg_activity ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    224    223    224            f           2604    17166    users id    DEFAULT     d   ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
 7   ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
       public               postgres    false    218    217    218                      0    17174    admins 
   TABLE DATA           J   COPY public.admins (id, firstname, lastname, email, password) FROM stdin;
    public               postgres    false    220   >*                 0    17185    questionnaire_responses 
   TABLE DATA           g   COPY public.questionnaire_responses (id, user_id, faculty, year, preference, submitted_at) FROM stdin;
    public               postgres    false    222   �*                 0    17200    sdg_activity 
   TABLE DATA           P   COPY public.sdg_activity (id, user_id, sdg_id, action, "timestamp") FROM stdin;
    public               postgres    false    224   +                 0    17163    users 
   TABLE DATA           Q   COPY public.users (id, firstname, lastname, email, password, active) FROM stdin;
    public               postgres    false    218   �+                  0    0    admins_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.admins_id_seq', 8, true);
          public               postgres    false    219                        0    0    questionnaire_responses_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.questionnaire_responses_id_seq', 2, true);
          public               postgres    false    221            !           0    0    sdg_activity_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.sdg_activity_id_seq', 5, true);
          public               postgres    false    223            "           0    0    users_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('public.users_id_seq', 3, true);
          public               postgres    false    217            s           2606    17183    admins admins_email_key 
   CONSTRAINT     S   ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_email_key UNIQUE (email);
 A   ALTER TABLE ONLY public.admins DROP CONSTRAINT admins_email_key;
       public                 postgres    false    220            u           2606    17181    admins admins_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.admins DROP CONSTRAINT admins_pkey;
       public                 postgres    false    220            w           2606    17193 4   questionnaire_responses questionnaire_responses_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.questionnaire_responses
    ADD CONSTRAINT questionnaire_responses_pkey PRIMARY KEY (id);
 ^   ALTER TABLE ONLY public.questionnaire_responses DROP CONSTRAINT questionnaire_responses_pkey;
       public                 postgres    false    222            y           2606    17209    sdg_activity sdg_activity_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.sdg_activity
    ADD CONSTRAINT sdg_activity_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.sdg_activity DROP CONSTRAINT sdg_activity_pkey;
       public                 postgres    false    224            o           2606    17172    users users_email_key 
   CONSTRAINT     Q   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT users_email_key;
       public                 postgres    false    218            q           2606    17170    users users_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public                 postgres    false    218            z           2606    17194 <   questionnaire_responses questionnaire_responses_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.questionnaire_responses
    ADD CONSTRAINT questionnaire_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
 f   ALTER TABLE ONLY public.questionnaire_responses DROP CONSTRAINT questionnaire_responses_user_id_fkey;
       public               postgres    false    218    4721    222            {           2606    17210 &   sdg_activity sdg_activity_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sdg_activity
    ADD CONSTRAINT sdg_activity_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);
 P   ALTER TABLE ONLY public.sdg_activity DROP CONSTRAINT sdg_activity_user_id_fkey;
       public               postgres    false    224    218    4721               c   x�3�tL����-N-�L1J�����9U��T�T�
���2�R#��r-���
-K��<+Ҋ+�,�ܝ�R�=,��M���RC����b���� z��         S   x��˱� �:����o �ֶv�z���
��)ʹ׳��H�K[w{��	�Ă�I੸J\`X����M]J�P�����4��         o   x�m�=�` й=���?�gaqp ap�x{?،�/O�@������yc��օB��P����Qޚ-BUa�h�����ۅ<�RЇҫ˥�HY��TסfZ�ĕ�&e&�         �   x�5���   �3>�g5�[���m]�X�&-�ʧ���߇A�6���4$oi
sW�����r���'s����s��
��N-Q�°:�m���M�O��k�'4��`�+΂
�D���~Y������<nl{V������?��h5@)g�ާ[�d�E5T���LtM�(פ��8�:�����}�#t��A     