--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 17.5 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA IF NOT EXISTS public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: actualizar_precio_unitario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.actualizar_precio_unitario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Sumar el precio de valor.precio al precio_unitario de detalle_pedido
        UPDATE detalle_pedido
        SET precio_unitario = precio_unitario + (
            SELECT precio
            FROM valor
            WHERE valor.valor = NEW.valor
        )
        WHERE detalle_pedido_id = NEW.detalle_pedido_id;

    ELSIF TG_OP = 'DELETE' THEN
        -- Restar el precio de valor.precio al precio_unitario de detalle_pedido
        UPDATE detalle_pedido
        SET precio_unitario = precio_unitario - (
            SELECT precio
            FROM valor
            WHERE valor.valor = OLD.valor
        )
        WHERE detalle_pedido_id = OLD.detalle_pedido_id;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.actualizar_precio_unitario() OWNER TO postgres;

--
-- Name: actualizar_total_pedido(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.actualizar_total_pedido() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verificar el tipo de operación
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Calcular la suma de (precio_unitario * cantidad) para el pedido relacionado
        UPDATE pedidos
        SET total = (
            SELECT COALESCE(SUM(precio_unitario * cantidad), 0)
            FROM detalle_pedido
            WHERE pedido_id = NEW.pedido_id
        )
        WHERE pedido_id = NEW.pedido_id;

    ELSIF TG_OP = 'DELETE' THEN
        -- Calcular la suma de (precio_unitario * cantidad) para el pedido relacionado usando OLD.pedido_id
        UPDATE pedidos
        SET total = (
            SELECT COALESCE(SUM(precio_unitario * cantidad), 0)
            FROM detalle_pedido
            WHERE pedido_id = OLD.pedido_id
        )
        WHERE pedido_id = OLD.pedido_id;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.actualizar_total_pedido() OWNER TO postgres;

--
-- Name: calculate_variant_details(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_variant_details() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Only run this when we have a complete variant (after variant_valores are inserted)
    IF TG_TABLE_NAME = 'variante_valores' THEN
        -- Update the variant with calculated SKU and price
        UPDATE public.variantes v
        SET
            sku = CONCAT(p.producto_id, '-', (
                SELECT STRING_AGG(
                               CASE
                                   WHEN LENGTH(val.valor) <= 3 THEN val.valor
                                   ELSE LEFT(val.valor, 3)
                                   END,
                               '-' ORDER BY esp.especificacion_id)
                FROM public.variante_valores vv
                         JOIN public.valor val ON vv.valor_id = val.valor_id
                         JOIN public.especificacion esp ON val.especificacion_id = esp.especificacion_id
                WHERE vv.variante_id = v.variante_id
            )),
            precio_total = p.precio_base + (
                SELECT COALESCE(SUM(val.precio), 0)
                FROM public.variante_valores vv
                         JOIN public.valor val ON vv.valor_id = val.valor_id
                WHERE vv.variante_id = v.variante_id
            )
        FROM public.productos p
        WHERE v.producto_id = p.producto_id
          AND v.variante_id = NEW.variante_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.calculate_variant_details() OWNER TO postgres;

--
-- Name: crear_pedido_con_validacion(character varying, character varying, character varying, text, integer, timestamp without time zone, time without time zone, jsonb); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.crear_pedido_con_validacion(IN p_pedido_id character varying, IN p_cliente_id character varying, IN p_usuario_id character varying, IN p_notas text, IN p_metodo_id integer, IN p_fecha_estimada_entrega timestamp without time zone, IN p_hora_estimada_entrega time without time zone, IN p_detalles jsonb)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC(10,2) := 0;
    v_detalle JSONB;
    v_detalle_id VARCHAR(30);
    v_especificaciones JSONB;
    v_counter INTEGER := 1;
    v_producto_precio NUMERIC(10,2);
    v_producto_id VARCHAR(5);
    v_cantidad INTEGER;
    v_subtotal NUMERIC(10,2);
    v_hay_stock BOOLEAN;
    v_error_msg TEXT;
    v_esp_par RECORD;
BEGIN
    -- Resto del código...
    
    -- Procesar cada detalle del pedido
    FOR v_detalle IN SELECT * FROM jsonb_array_elements(p_detalles)
    LOOP
        -- Parte del código anterior...
        
        -- Insertar especificaciones del producto
        IF v_especificaciones IS NOT NULL THEN
            -- Aquí está la corrección:
            FOR v_esp_par IN 
                SELECT key::INTEGER AS esp_id, value AS esp_valor
                FROM jsonb_each_text(v_especificaciones)
            LOOP
                INSERT INTO pedido_especificacion (
                    pedido_especificacion_id, 
                    detalle_pedido_id, 
                    especificacion_id, 
                    valor
                ) VALUES (
                    v_producto_id || '-' || v_esp_par.esp_id || LPAD(v_counter::TEXT, 3, '0'),
                    v_detalle_id, 
                    v_esp_par.esp_id,
                    v_esp_par.esp_valor
                );
            END LOOP;
        END IF;
        
        -- Resto del código...
    END LOOP;
    
    -- Resto del código...
END;
$$;


ALTER PROCEDURE public.crear_pedido_con_validacion(IN p_pedido_id character varying, IN p_cliente_id character varying, IN p_usuario_id character varying, IN p_notas text, IN p_metodo_id integer, IN p_fecha_estimada_entrega timestamp without time zone, IN p_hora_estimada_entrega time without time zone, IN p_detalles jsonb) OWNER TO postgres;

--
-- Name: set_precio_unitario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_precio_unitario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Asignar el precio_base del producto al precio_unitario
    NEW.precio_unitario := (SELECT precio_base FROM productos WHERE producto_id = NEW.producto_id);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_precio_unitario() OWNER TO postgres;

--
-- Name: verificar_disponibilidad_inventario(character varying, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verificar_disponibilidad_inventario(p_producto_id character varying, p_cantidad integer, p_especificaciones jsonb) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_stock_disponible INTEGER;
    v_inventario_id VARCHAR(20);
BEGIN
    -- Buscar el inventario correspondiente a las especificaciones
    SELECT ie.inventario_especificacion_id, ie.stock INTO v_inventario_id, v_stock_disponible
    FROM inventario_especificacion ie
    JOIN inventario_producto ip ON ie.inventario_producto_id = ip.inventario_producto_id
    WHERE ip.producto_id = p_producto_id
    AND (
        -- Verificar que todas las especificaciones coincidan
        SELECT COUNT(*) = jsonb_array_length(
            (SELECT jsonb_agg(json_build_object('esp', esp_id, 'val', valor)) 
             FROM jsonb_each_text(p_especificaciones) AS t(esp_id, valor))
        )
        FROM inventario_especificacion_valor iev
        WHERE iev.inventario_especificacion_id = ie.inventario_especificacion_id
        AND EXISTS (
            SELECT 1 
            FROM jsonb_each_text(p_especificaciones) AS t(esp_id, valor)
            WHERE iev.especificacion_id::text = esp_id 
            AND iev.valor = valor
        )
    );
    
    -- Si no se encuentra inventario o el stock es insuficiente
    IF v_inventario_id IS NULL OR v_stock_disponible < p_cantidad THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$;


ALTER FUNCTION public.verificar_disponibilidad_inventario(p_producto_id character varying, p_cantidad integer, p_especificaciones jsonb) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bitacora; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bitacora (
    bitacora_id integer NOT NULL,
    usuario_id character varying(50),
    metodo character varying(10) NOT NULL,
    endpoint character varying(255) NOT NULL,
    descripcion text,
    fecha_hora timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    estatus_respuesta integer
);


ALTER TABLE public.bitacora OWNER TO postgres;

--
-- Name: bitacora_bitacora_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bitacora_bitacora_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bitacora_bitacora_id_seq OWNER TO postgres;

--
-- Name: bitacora_bitacora_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bitacora_bitacora_id_seq OWNED BY public.bitacora.bitacora_id;


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clientes (
    cliente_id character varying(10) NOT NULL,
    nombre character varying(100) NOT NULL,
    telefono character varying(10) NOT NULL,
    correo character varying(50),
    direccion text,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.clientes OWNER TO postgres;

--
-- Name: detalle_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_pedido (
    detalle_pedido_id character varying(30) NOT NULL,
    pedido_id character varying(20) NOT NULL,
    producto_id character varying(10) NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) DEFAULT 0.0,
    nota text
);


ALTER TABLE public.detalle_pedido OWNER TO postgres;

--
-- Name: especificacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.especificacion (
    especificacion_id integer NOT NULL,
    nombre character varying(50)
);


ALTER TABLE public.especificacion OWNER TO postgres;

--
-- Name: estados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estados (
    estado_id integer NOT NULL,
    nombre character varying(50) NOT NULL
);


ALTER TABLE public.estados OWNER TO postgres;

--
-- Name: metodo_envio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.metodo_envio (
    metodo_id integer NOT NULL,
    nombre character varying(50) NOT NULL
);


ALTER TABLE public.metodo_envio OWNER TO postgres;

--
-- Name: pedido_especificacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedido_especificacion (
    pedido_especificacion_id character varying(10) NOT NULL,
    detalle_pedido_id character varying(30) NOT NULL,
    especificacion_id integer NOT NULL,
    valor character varying(20) NOT NULL
);


ALTER TABLE public.pedido_especificacion OWNER TO postgres;

--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedidos (
    pedido_id character varying(20) NOT NULL,
    cliente_id character varying(10) NOT NULL,
    usuario_id character varying(10) NOT NULL,
    notas text,
    estado_id integer DEFAULT 1 NOT NULL,
    total numeric(10,2) DEFAULT 0.00 NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_finalizacion timestamp without time zone,
    fecha_estimada_entrega timestamp without time zone,
    metodo_id integer,
    hora_estimada_entrega time without time zone,
    CONSTRAINT check_hora_entrega CHECK ((((hora_estimada_entrega >= '08:00:00'::time without time zone) AND (hora_estimada_entrega <= '17:00:00'::time without time zone)) OR (hora_estimada_entrega IS NULL)))
);


ALTER TABLE public.pedidos OWNER TO postgres;

--
-- Name: producto_especificaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producto_especificaciones (
    producto_id character varying NOT NULL,
    especificacion_id integer NOT NULL
);


ALTER TABLE public.producto_especificaciones OWNER TO postgres;

--
-- Name: productos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.productos (
    producto_id character varying(10) NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion character varying(100),
    precio_base integer NOT NULL
);


ALTER TABLE public.productos OWNER TO postgres;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refresh_tokens (
    id integer NOT NULL,
    token text NOT NULL,
    usuario_id character varying(10) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.refresh_tokens OWNER TO postgres;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.refresh_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.refresh_tokens_id_seq OWNER TO postgres;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.refresh_tokens_id_seq OWNED BY public.refresh_tokens.id;


--
-- Name: rol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rol (
    rol_id character varying(20) NOT NULL,
    nombre character varying(50) NOT NULL
);


ALTER TABLE public.rol OWNER TO postgres;

--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    usuario_id character varying(10) NOT NULL,
    nombre character varying(100) NOT NULL,
    nombre_usuario character varying(20) NOT NULL,
    rol character varying(10) NOT NULL,
    correo character varying(100),
    contrasena text NOT NULL
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_usuario_seq OWNER TO postgres;

--
-- Name: valor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.valor (
    especificacion_id integer NOT NULL,
    valor character varying(30) NOT NULL,
    precio integer NOT NULL,
    valor_id integer NOT NULL
);


ALTER TABLE public.valor OWNER TO postgres;

--
-- Name: valor_valor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.valor_valor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.valor_valor_id_seq OWNER TO postgres;

--
-- Name: valor_valor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.valor_valor_id_seq OWNED BY public.valor.valor_id;


--
-- Name: variante_valores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.variante_valores (
    variante_valores_id integer NOT NULL,
    variante_id integer NOT NULL,
    valor_id integer NOT NULL
);


ALTER TABLE public.variante_valores OWNER TO postgres;

--
-- Name: variante_valores_variante_valores_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.variante_valores_variante_valores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.variante_valores_variante_valores_id_seq OWNER TO postgres;

--
-- Name: variante_valores_variante_valores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.variante_valores_variante_valores_id_seq OWNED BY public.variante_valores.variante_valores_id;


--
-- Name: variantes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.variantes (
    variante_id integer NOT NULL,
    producto_id character varying(10) NOT NULL,
    sku character varying(255),
    precio_total numeric(10,2),
    stock integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.variantes OWNER TO postgres;

--
-- Name: variantes_variante_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.variantes_variante_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.variantes_variante_id_seq OWNER TO postgres;

--
-- Name: variantes_variante_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.variantes_variante_id_seq OWNED BY public.variantes.variante_id;


--
-- Name: bitacora bitacora_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bitacora ALTER COLUMN bitacora_id SET DEFAULT nextval('public.bitacora_bitacora_id_seq'::regclass);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('public.refresh_tokens_id_seq'::regclass);


--
-- Name: valor valor_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.valor ALTER COLUMN valor_id SET DEFAULT nextval('public.valor_valor_id_seq'::regclass);


--
-- Name: variante_valores variante_valores_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variante_valores ALTER COLUMN variante_valores_id SET DEFAULT nextval('public.variante_valores_variante_valores_id_seq'::regclass);


--
-- Name: variantes variante_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variantes ALTER COLUMN variante_id SET DEFAULT nextval('public.variantes_variante_id_seq'::regclass);


--
-- Data for Name: bitacora; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bitacora (bitacora_id, usuario_id, metodo, endpoint, descripcion, fecha_hora, estatus_respuesta) FROM stdin;
1	No autenticado	GET	/api/clientes	Consulta de /api/clientes	2025-04-24 04:51:23.372891	200
2	A002	GET	/api/clientes	Consulta de /api/clientes	2025-04-24 04:58:03.885992	304
3	A002	GET	/api/clientes/CL004	Consulta de /api/clientes/CL004	2025-04-24 04:58:30.939474	304
4	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 05:06:35.147694	304
5	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 05:06:35.152966	304
6	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 05:06:35.158578	304
7	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 05:06:35.159763	304
8	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 05:06:35.162023	304
9	A002	GET	/api/clientes	Consulta de /api/clientes	2025-04-24 05:07:10.554732	200
10	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 05:18:45.800951	304
11	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 05:18:45.802161	304
12	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 05:18:45.810055	304
13	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 05:18:45.814509	200
14	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 05:18:45.815764	304
15	No autenticado	GET	/api/docs/favicon-32x32.png	Consulta de /api/docs/favicon-32x32.png	2025-04-24 05:18:45.873456	304
16	No autenticado	GET	/api/pedidos	Consulta de /api/pedidos	2025-04-24 05:18:52.646323	401
17	No autenticado	GET	/api/pedidos	Consulta de /api/pedidos	2025-04-24 05:19:03.07157	403
18	No autenticado	GET	/api/pedidos	Consulta de /api/pedidos	2025-04-24 05:19:04.055163	403
19	No autenticado	POST	/api/auth/sign-in	Creación en /api/auth/sign-in con datos: {"nombre_usuario":"driosp","contrasena":"StrongPassword123!"}	2025-04-24 05:19:06.338173	200
20	A002	GET	/api/pedidos	Consulta de /api/pedidos	2025-04-24 05:19:16.903095	200
21	A002	GET	/api/pedidos/250113-PDD078	Consulta de /api/pedidos/250113-PDD078	2025-04-24 05:19:29.225062	200
22	A002	GET	/api/estados	Consulta de /api/estados	2025-04-24 05:19:34.989302	304
23	A002	PUT	/api/pedidos/250113-PDD078/estado	Actualización en /api/pedidos/250113-PDD078/estado con datos: {"estado_id":3}	2025-04-24 05:19:55.910363	200
24	A002	GET	/api/pedidos/250113-PDD078	Consulta de /api/pedidos/250113-PDD078	2025-04-24 05:20:02.608075	200
25	A002	GET	/api/pedidos	Consulta de /api/pedidos	2025-04-24 05:20:18.156052	200
26	A002	GET	/api/pedidos/250113-PDD078	Consulta de /api/pedidos/250113-PDD078	2025-04-24 05:20:56.865777	304
27	A002	GET	/api/pedidos	Consulta de /api/pedidos	2025-04-24 05:24:52.750955	304
28	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 05:44:28.44535	200
29	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 05:44:28.450512	304
30	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 05:44:28.537156	304
31	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 05:44:28.537576	304
32	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 05:44:28.546787	200
33	No autenticado	GET	/api/docs/favicon-32x32.png	Consulta de /api/docs/favicon-32x32.png	2025-04-24 05:44:28.739635	304
34	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 05:46:42.754135	304
35	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 05:46:42.773242	304
36	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 05:46:42.773444	304
37	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 05:46:42.774205	304
38	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 05:46:42.780407	304
39	No autenticado	GET	/api/docs/favicon-32x32.png	Consulta de /api/docs/favicon-32x32.png	2025-04-24 05:46:42.821736	304
40	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 05:46:43.980995	304
41	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 05:46:43.990618	304
42	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 05:46:43.99138	304
43	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 05:46:43.991539	304
44	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 05:46:43.991658	304
45	No autenticado	GET	/api/docs/favicon-32x32.png	Consulta de /api/docs/favicon-32x32.png	2025-04-24 05:46:44.033495	304
46	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 05:46:59.761629	304
47	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 05:46:59.761715	304
48	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 05:46:59.762058	304
49	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 05:46:59.762319	304
50	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 05:46:59.771564	200
51	No autenticado	GET	/api/docs/favicon-32x32.png	Consulta de /api/docs/favicon-32x32.png	2025-04-24 05:46:59.785417	304
52	No autenticado	GET	/api/clientes	Consulta de /api/clientes	2025-04-24 05:47:03.287146	401
53	No autenticado	POST	/api/auth/sign-in	Creación en /api/auth/sign-in con datos: {"nombre_usuario":"driosp","contrasena":"StrongPassword123!"}	2025-04-24 05:47:07.381829	200
54	A002	GET	/api/clientes	Consulta de /api/clientes	2025-04-24 05:47:15.032612	304
55	No autenticado	HEAD	/		2025-04-24 06:28:03.897397	200
56	No autenticado	GET	/	Consulta de /	2025-04-24 06:28:12.9837	200
57	No autenticado	GET	/api/docs	Consulta de /api/docs	2025-04-24 06:28:21.22861	301
58	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 06:28:21.479223	200
59	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 06:28:21.68637	200
60	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 06:28:21.916139	200
61	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 06:28:21.998484	200
62	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 06:28:22.008067	200
63	No autenticado	GET	/api/docs/favicon-32x32.png	Consulta de /api/docs/favicon-32x32.png	2025-04-24 06:28:22.988197	200
64	No autenticado	POST	/api/auth/sign-in	Creación en /api/auth/sign-in con datos: {"nombre_usuario":"driosp","contrasena":"StrongPassword123!"}	2025-04-24 06:29:20.590628	200
65	No autenticado	GET	/api/	Consulta de /api/	2025-04-24 06:32:34.306733	404
66	No autenticado	GET	/	Consulta de /	2025-04-24 06:32:40.735746	200
67	No autenticado	GET	/favicon.ico	Consulta de /favicon.ico	2025-04-24 06:32:40.950695	404
68	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 06:34:36.185459	304
69	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 06:34:36.260268	304
70	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 06:34:36.327775	304
71	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 06:34:36.336105	304
72	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 06:34:36.415233	304
73	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 06:37:45.450058	304
74	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 06:37:45.580729	304
75	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 06:37:45.599323	304
76	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 06:37:45.75001	304
77	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 06:37:45.758822	304
78	No autenticado	POST	/api/auth/sign-in	Creación en /api/auth/sign-in con datos: {"nombre_usuario":"driosp","contrasena":"StrongPassword123!"}	2025-04-24 06:44:04.346237	200
79	No autenticado	GET	/favicon.ico	Consulta de /favicon.ico	2025-04-24 21:37:34.0134	404
80	No autenticado	GET	/	Consulta de /	2025-04-24 21:37:34.020433	200
81	No autenticado	GET	/api/metodos-de-envio	Consulta de /api/metodos-de-envio	2025-04-24 21:38:18.201323	401
82	No autenticado	GET	/api/usuarios	Consulta de /api/usuarios	2025-04-24 21:38:51.031321	401
83	No autenticado	GET	/	Consulta de /	2025-04-24 23:05:48.779592	200
84	No autenticado	GET	/favicon.ico	Consulta de /favicon.ico	2025-04-24 23:05:48.909168	404
85	No autenticado	GET	/api/docs/	Consulta de /api/docs/	2025-04-24 23:05:48.940773	200
86	No autenticado	GET	/api/docs/swagger-ui-standalone-preset.js	Consulta de /api/docs/swagger-ui-standalone-preset.js	2025-04-24 23:05:49.063299	200
87	No autenticado	GET	/api/docs/swagger-ui.css	Consulta de /api/docs/swagger-ui.css	2025-04-24 23:05:49.072397	200
88	No autenticado	GET	/api/docs/swagger-ui-bundle.js	Consulta de /api/docs/swagger-ui-bundle.js	2025-04-24 23:05:49.080217	200
89	No autenticado	GET	/api/docs/swagger-ui-init.js	Consulta de /api/docs/swagger-ui-init.js	2025-04-24 23:05:49.228986	200
90	No autenticado	GET	/api/docs/favicon-32x32.png	Consulta de /api/docs/favicon-32x32.png	2025-04-24 23:05:49.395655	200
91	No autenticado	GET	/api/docs/favicon-32x32.png	Consulta de /api/docs/favicon-32x32.png	2025-04-24 23:05:49.90683	304
92	No autenticado	GET	/apple-touch-icon-precomposed.png	Consulta de /apple-touch-icon-precomposed.png	2025-04-24 23:14:25.094093	404
93	No autenticado	GET	/apple-touch-icon.png	Consulta de /apple-touch-icon.png	2025-04-24 23:14:25.099822	404
94	No autenticado	GET	/favicon.ico	Consulta de /favicon.ico	2025-04-24 23:14:25.260028	404
95	No autenticado	GET	/	Consulta de /	2025-04-24 23:14:25.271354	200
96	No autenticado	GET	/api/auth/sign-up	Consulta de /api/auth/sign-up	2025-04-24 23:14:43.806962	404
97	No autenticado	POST	/api/auth/sign-up	Creación en /api/auth/sign-up	2025-04-24 23:14:47.781035	401
98	No autenticado	POST	/api/auth/sign-up	Creación en /api/auth/sign-up con datos: {"nombre":"Juan Alvarenga","nombre_usuario":"jalvarenga","rol":0,"correo":"jealvarengar@unah.edu.hn","contrasena":"12341234"}	2025-04-24 23:15:25.177108	401
99	No autenticado	POST	/api/auth/sign-up	Creación en /api/auth/sign-up con datos: {"nombre":"Juan Alvarenga","nombre_usuario":"jalvarenga","rol":0,"correo":"jealvarengar@unah.edu.hn","contrasena":"12341234"}	2025-04-24 23:16:53.579398	401
\.


--
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clientes (cliente_id, nombre, telefono, correo, direccion, activo) FROM stdin;
RSA001	Roberto Sanchez Aguilar	94959614	elroberto@gmail.com	Colonia Jardines del Sol	t
CL002	María Fernanda López	94837261	maria.lopez@gmail.com	Colonia Las Flores	t
CL003	Carlos Alberto Gómez	94726183	carlos.gomez@hotmail.com	Residencial Los Pinos	t
CL004	Ana Patricia Martínez	94618273	ana.martinez@yahoo.com	Barrio El Centro	t
CL005	José Luis Rodríguez	94537281	jose.rodriguez@outlook.com	Colonia San José	t
CL006	Laura Beatriz Pérez	94418276	laura.perez@gmail.com	Residencial La Esperanza	t
CL007	Andrés Felipe Ramírez	94328176	andres.ramirez@gmail.com	Colonia Los Laureles	t
CL008	Claudia Isabel Torres	94237185	claudia.torres@hotmail.com	Residencial El Prado	t
CL009	Fernando Antonio Castillo	94187263	fernando.castillo@yahoo.com	Barrio La Merced	t
CL010	Sofía Alejandra Morales	94018273	sofia.morales@gmail.com	Colonia El Paraíso	t
CL011	Diego Armando Vargas	94928371	diego.vargas@outlook.com	Residencial Los Álamos	t
CL012	Valeria Carolina Méndez	94817262	valeria.mendez@gmail.com	Barrio San Miguel	t
CL013	Juan Pablo Herrera	94738262	juan.herrera@hotmail.com	Colonia Las Acacias	t
CL014	Paola Andrea Rojas	94628174	paola.rojas@yahoo.com	Residencial El Bosque	t
CL015	Daniel Esteban Cruz	94517284	daniel.cruz@gmail.com	Barrio La Esperanza	t
CL016	Carolina Beatriz Soto	94437282	carolina.soto@gmail.com	Colonia Los Cedros	t
CL017	José Antonio López	94318277	jose.lopez@hotmail.com	Residencial Las Palmas	t
CL018	Mariana Isabel García	94228174	mariana.garcia@yahoo.com	Barrio El Carmen	t
CL019	Luis Fernando Pérez	94137282	luis.perez@gmail.com	Colonia San Antonio	t
CL020	Andrea Patricia Ramírez	94028177	andrea.ramirez@gmail.com	Residencial Los Robles	t
CL021	Francisco Javier Torres	94917284	francisco.torres@outlook.com	Barrio La Unión	t
CL022	Isabel Cristina Morales	94828174	isabel.morales@gmail.com	Colonia Las Margaritas	t
CL023	Pedro Alejandro Vargas	94717264	pedro.vargas@hotmail.com	Residencial El Sol	t
CL024	Lucía Fernanda Méndez	94637282	lucia.mendez@yahoo.com	Barrio San Rafael	t
CL025	Martín Eduardo Herrera	94528174	martin.herrera@gmail.com	Colonia Los Ángeles	t
CL026	Daniela Alejandra Rojas	94417284	daniela.rojas@gmail.com	Residencial La Luz	t
CL027	José Manuel Cruz	94328177	jose.cruz@hotmail.com	Barrio La Paz	t
CL028	María Isabel Soto	94237282	maria.soto@yahoo.com	Colonia El Jardín	t
CL029	Juan Carlos García	94128174	juan.garcia@gmail.com	Residencial Las Rosas	t
CL030	Paula Andrea Pérez	94037282	paula.perez@gmail.com	Barrio San Juan	t
CL031	Roberto Carlos Sánchez	94937282	roberto.sanchez@gmail.com	Colonia Los Laureles	t
CL032	Elena Patricia López	94817284	elena.lopez@hotmail.com	Residencial El Prado	t
CL033	Oscar Eduardo Gómez	94728174	oscar.gomez@yahoo.com	Barrio La Merced	t
CL034	María Fernanda Torres	94637283	maria.torres@gmail.com	Colonia El Paraíso	t
CL035	José Luis Morales	94517285	jose.morales@outlook.com	Residencial Los Álamos	t
CL036	Laura Isabel Méndez	94428175	laura.mendez@gmail.com	Barrio San Miguel	t
CL037	Andrés Felipe Herrera	94317284	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL038	Claudia Patricia Rojas	94237283	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL039	Fernando Antonio Cruz	94117284	fernando.cruz@gmail.com	Barrio La Esperanza	t
CL040	Sofía Alejandra Soto	94037283	sofia.soto@gmail.com	Colonia Los Cedros	t
CL041	Diego Armando García	94917285	diego.garcia@outlook.com	Residencial Las Palmas	t
CL042	Valeria Carolina Pérez	94837282	valeria.perez@gmail.com	Barrio El Carmen	t
CL043	Juan Pablo Ramírez	94717285	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL044	Paola Andrea Torres	94628175	paola.torres@yahoo.com	Residencial Los Robles	t
CL045	Daniel Esteban Morales	94537282	daniel.morales@gmail.com	Barrio La Unión	t
CL046	Carolina Beatriz Méndez	94417285	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL047	José Antonio Herrera	94328178	jose.herrera@hotmail.com	Residencial El Sol	t
CL048	Mariana Isabel Rojas	94217284	mariana.rojas@yahoo.com	Barrio San Rafael	t
CL049	Luis Fernando Cruz	94137283	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL050	Andrea Patricia Soto	94017284	andrea.soto@gmail.com	Residencial La Luz	t
CL051	Francisco Javier García	94928174	francisco.garcia@gmail.com	Barrio La Paz	t
CL052	Isabel Cristina Pérez	94817285	isabel.perez@hotmail.com	Colonia El Jardín	t
CL053	Pedro Alejandro Ramírez	94737282	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL054	Lucía Fernanda Torres	94617285	lucia.torres@gmail.com	Colonia San Juan	t
CL055	Martín Eduardo Morales	94528175	martin.morales@outlook.com	Colonia Los Laureles	t
CL056	Daniela Alejandra Méndez	94437283	daniela.mendez@gmail.com	Residencial El Prado	t
CL057	José Manuel Herrera	94317285	jose.herrera@hotmail.com	Barrio La Merced	t
CL058	María Isabel Rojas	94228175	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL059	Juan Carlos Cruz	94137284	juan.cruz@gmail.com	Residencial Los Álamos	t
CL060	Paula Andrea Soto	94017285	paula.soto@gmail.com	Barrio San Miguel	t
CL061	Francisco Javier García	87654321	francisco.garcia@gmail.com	Barrio La Paz	t
CL062	Isabel Cristina Pérez	76543218	isabel.perez@hotmail.com	Colonia El Jardín	t
CL063	Pedro Alejandro Ramírez	65432187	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL064	Lucía Fernanda Torres	54321876	lucia.torres@gmail.com	Colonia San Juan	t
CL065	Martín Eduardo Morales	43218765	martin.morales@outlook.com	Colonia Los Laureles	t
CL066	Daniela Alejandra Méndez	32187654	daniela.mendez@gmail.com	Residencial El Prado	t
CL067	José Manuel Herrera	21098765	jose.herrera@hotmail.com	Barrio La Merced	t
CL068	María Isabel Rojas	19876543	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL069	Juan Carlos Cruz	98765432	juan.cruz@gmail.com	Residencial Los Álamos	t
CL070	Paula Andrea Soto	87654322	paula.soto@gmail.com	Barrio San Miguel	t
CL071	Roberto Carlos Sánchez	76543219	roberto.sanchez@gmail.com	Colonia Las Acacias	t
CL072	Elena Patricia López	65432188	elena.lopez@hotmail.com	Residencial El Prado	t
CL073	Oscar Eduardo Gómez	54321877	oscar.gomez@yahoo.com	Barrio La Merced	t
CL074	María Fernanda Torres	43218766	maria.torres@gmail.com	Colonia El Paraíso	t
CL075	José Luis Morales	32187655	jose.morales@outlook.com	Residencial Los Álamos	t
CL076	Laura Isabel Méndez	21098766	laura.mendez@gmail.com	Barrio San Miguel	t
CL077	Andrés Felipe Herrera	19876544	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL078	Claudia Patricia Rojas	98765433	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL079	Fernando Antonio Cruz	87654323	fernando.cruz@gmail.com	Barrio La Esperanza	t
CL080	Sofía Alejandra Soto	76543220	sofia.soto@gmail.com	Colonia Los Cedros	t
CL081	Diego Armando García	65432189	diego.garcia@outlook.com	Residencial Las Palmas	t
CL082	Valeria Carolina Pérez	54321878	valeria.perez@gmail.com	Barrio El Carmen	t
CL083	Juan Pablo Ramírez	43218767	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL084	Paola Andrea Torres	32187656	paola.torres@yahoo.com	Residencial Los Robles	t
CL085	Daniel Esteban Morales	21098767	daniel.morales@gmail.com	Barrio La Unión	t
CL086	Carolina Beatriz Méndez	19876545	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL087	José Antonio Herrera	98765434	jose.herrera@hotmail.com	Residencial El Sol	t
CL088	Mariana Isabel Rojas	87654324	mariana.rojas@yahoo.com	Barrio San Rafael	t
CL089	Luis Fernando Cruz	76543221	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL090	Andrea Patricia Soto	65432190	andrea.soto@gmail.com	Residencial La Luz	t
CL091	Francisco Javier García	54321879	francisco.garcia@gmail.com	Barrio La Paz	t
CL092	Isabel Cristina Pérez	43218768	isabel.perez@hotmail.com	Colonia El Jardín	t
CL093	Pedro Alejandro Ramírez	32187657	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL094	Lucía Fernanda Torres	21098768	lucia.torres@gmail.com	Colonia San Juan	t
CL095	Martín Eduardo Morales	19876546	martin.morales@outlook.com	Colonia Los Laureles	t
CL096	Daniela Alejandra Méndez	98765435	daniela.mendez@gmail.com	Residencial El Prado	t
CL097	José Manuel Herrera	87654325	jose.herrera@hotmail.com	Barrio La Merced	t
CL098	María Isabel Rojas	76543222	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL099	Juan Carlos Cruz	65432191	juan.cruz@gmail.com	Residencial Los Álamos	t
CL100	Paula Andrea Soto	54321880	paula.soto@gmail.com	Barrio San Miguel	t
CL101	Roberto Carlos Sánchez	43218769	roberto.sanchez@gmail.com	Colonia Las Acacias	t
CL102	Elena Patricia López	32187658	elena.lopez@hotmail.com	Residencial El Prado	t
CL103	Oscar Eduardo Gómez	21098769	oscar.gomez@yahoo.com	Barrio La Merced	t
CL104	María Fernanda Torres	19876547	maria.torres@gmail.com	Colonia El Paraíso	t
CL105	José Luis Morales	98765436	jose.morales@outlook.com	Residencial Los Álamos	t
CL106	Laura Isabel Méndez	87654326	laura.mendez@gmail.com	Barrio San Miguel	t
CL107	Andrés Felipe Herrera	76543223	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL108	Claudia Patricia Rojas	65432192	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL109	Fernando Antonio Cruz	54321881	fernando.cruz@gmail.com	Barrio La Esperanza	t
CL110	Sofía Alejandra Soto	43218770	sofia.soto@gmail.com	Colonia Los Cedros	t
CL111	Diego Armando García	32187659	diego.garcia@outlook.com	Residencial Las Palmas	t
CL112	Valeria Carolina Pérez	21098770	valeria.perez@gmail.com	Barrio El Carmen	t
CL113	Juan Pablo Ramírez	19876548	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL114	Paola Andrea Torres	98765437	paola.torres@yahoo.com	Residencial Los Robles	t
CL115	Daniel Esteban Morales	87654327	daniel.morales@gmail.com	Barrio La Unión	t
CL116	Carolina Beatriz Méndez	76543224	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL117	José Antonio Herrera	65432193	jose.herrera@hotmail.com	Residencial El Sol	t
CL118	Mariana Isabel Rojas	54321882	mariana.rojas@yahoo.com	Barrio San Rafael	t
CL119	Luis Fernando Cruz	43218771	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL120	Andrea Patricia Soto	32187660	andrea.soto@gmail.com	Residencial La Luz	t
CL121	Francisco Javier García	21098771	francisco.garcia@gmail.com	Barrio La Paz	t
CL122	Isabel Cristina Pérez	19876549	isabel.perez@hotmail.com	Colonia El Jardín	t
CL123	Pedro Alejandro Ramírez	98765438	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL124	Lucía Fernanda Torres	87654328	lucia.torres@gmail.com	Colonia San Juan	t
CL125	Martín Eduardo Morales	76543225	martin.morales@outlook.com	Colonia Los Laureles	t
CL126	Daniela Alejandra Méndez	65432194	daniela.mendez@gmail.com	Residencial El Prado	t
CL127	José Manuel Herrera	54321883	jose.herrera@hotmail.com	Barrio La Merced	t
CL128	María Isabel Rojas	43218772	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL129	Juan Carlos Cruz	32187661	juan.cruz@gmail.com	Residencial Los Álamos	t
CL130	Paula Andrea Soto	21098772	paula.soto@gmail.com	Barrio San Miguel	t
CL131	Roberto Carlos Sánchez	19876550	roberto.sanchez@gmail.com	Colonia Las Acacias	t
CL132	Elena Patricia López	98765439	elena.lopez@hotmail.com	Residencial El Prado	t
CL133	Oscar Eduardo Gómez	87654329	oscar.gomez@yahoo.com	Barrio La Merced	t
CL134	María Fernanda Torres	76543226	maria.torres@gmail.com	Colonia El Paraíso	t
CL135	José Luis Morales	65432195	jose.morales@outlook.com	Residencial Los Álamos	t
CL136	Laura Isabel Méndez	54321884	laura.mendez@gmail.com	Barrio San Miguel	t
CL137	Andrés Felipe Herrera	43218773	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL138	Claudia Patricia Rojas	32187662	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL139	Fernando Antonio Cruz	21098773	fernando.cruz@gmail.com	Barrio La Esperanza	t
CL140	Sofía Alejandra Soto	19876551	sofia.soto@gmail.com	Colonia Los Cedros	t
CL141	Diego Armando García	98765440	diego.garcia@outlook.com	Residencial Las Palmas	t
CL142	Valeria Carolina Pérez	87654330	valeria.perez@gmail.com	Barrio El Carmen	t
CL143	Juan Pablo Ramírez	76543227	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL144	Paola Andrea Torres	65432196	paola.torres@yahoo.com	Residencial Los Robles	t
CL145	Daniel Esteban Morales	54321885	daniel.morales@gmail.com	Barrio La Unión	t
CL146	Carolina Beatriz Méndez	43218774	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL147	José Antonio Herrera	32187663	jose.herrera@hotmail.com	Residencial El Sol	t
CL148	Mariana Isabel Rojas	21098774	mariana.rojas@yahoo.com	Barrio San Rafael	t
CL149	Luis Fernando Cruz	19876552	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL150	Andrea Patricia Soto	98765441	andrea.soto@gmail.com	Residencial La Luz	t
CL152	Isabel Cristina Pérez	76543228	isabel.perez@hotmail.com	Colonia El Jardín	t
CL153	Pedro Alejandro Ramírez	65432197	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL154	Lucía Fernanda Torres	54321886	lucia.torres@gmail.com	Colonia San Juan	t
CL155	Martín Eduardo Morales	43218775	martin.morales@outlook.com	Colonia Los Laureles	t
CL156	Daniela Alejandra Méndez	32187664	daniela.mendez@gmail.com	Residencial El Prado	t
CL157	José Manuel Herrera	21098775	jose.herrera@hotmail.com	Barrio La Merced	t
CL158	María Isabel Rojas	19876553	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL159	Juan Carlos Cruz	98765442	juan.cruz@gmail.com	Residencial Los Álamos	t
CL160	Paula Andrea Soto	87654332	paula.soto@gmail.com	Barrio San Miguel	t
CL161	Roberto Carlos Sánchez	76543229	roberto.sanchez@gmail.com	Colonia Las Acacias	t
CL162	Elena Patricia López	65432198	elena.lopez@hotmail.com	Residencial El Prado	t
CL163	Oscar Eduardo Gómez	54321887	oscar.gomez@yahoo.com	Barrio La Merced	t
CL164	María Fernanda Torres	43218776	maria.torres@gmail.com	Colonia El Paraíso	t
CL165	José Luis Morales	32187665	jose.morales@outlook.com	Residencial Los Álamos	t
CL166	Laura Isabel Méndez	21098776	laura.mendez@gmail.com	Barrio San Miguel	t
CL167	Andrés Felipe Herrera	19876554	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL168	Claudia Patricia Rojas	98765443	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL169	Fernando Antonio Cruz	87654333	fernando.cruz@gmail.com	Barrio La Esperanza	t
CL170	Sofía Alejandra Soto	76543230	sofia.soto@gmail.com	Colonia Los Cedros	t
CL171	Diego Armando García	65432199	diego.garcia@outlook.com	Residencial Las Palmas	t
CL172	Valeria Carolina Pérez	54321888	valeria.perez@gmail.com	Barrio El Carmen	t
CL173	Juan Pablo Ramírez	43218777	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL174	Paola Andrea Torres	32187666	paola.torres@yahoo.com	Residencial Los Robles	t
CL175	Daniel Esteban Morales	21098777	daniel.morales@gmail.com	Barrio La Unión	t
CL176	Carolina Beatriz Méndez	19876555	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL177	José Antonio Herrera	98765444	jose.herrera@hotmail.com	Residencial El Sol	t
CL178	Mariana Isabel Rojas	87654334	mariana.rojas@yahoo.com	Barrio San Rafael	t
CL179	Luis Fernando Cruz	76543231	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL180	Andrea Patricia Soto	65432200	andrea.soto@gmail.com	Residencial La Luz	t
CL181	Francisco Javier García	54321889	francisco.garcia@gmail.com	Barrio La Paz	t
CL182	Isabel Cristina Pérez	43218778	isabel.perez@hotmail.com	Colonia El Jardín	t
CL183	Pedro Alejandro Ramírez	32187667	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL184	Lucía Fernanda Torres	21098778	lucia.torres@gmail.com	Colonia San Juan	t
CL185	Martín Eduardo Morales	19876556	martin.morales@outlook.com	Colonia Los Laureles	t
CL186	Daniela Alejandra Méndez	98765445	daniela.mendez@gmail.com	Residencial El Prado	t
CL187	José Manuel Herrera	87654335	jose.herrera@hotmail.com	Barrio La Merced	t
CL188	María Isabel Rojas	76543232	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL189	Juan Carlos Cruz	65432201	juan.cruz@gmail.com	Residencial Los Álamos	t
CL190	Paula Andrea Soto	54321890	paula.soto@gmail.com	Barrio San Miguel	t
CL191	Roberto Carlos Sánchez	43218779	roberto.sanchez@gmail.com	Colonia Las Acacias	t
CL192	Elena Patricia López	32187668	elena.lopez@hotmail.com	Residencial El Prado	t
CL194	María Fernanda Torres	19876557	maria.torres@gmail.com	Colonia El Paraíso	t
CL195	José Luis Morales	98765446	jose.morales@outlook.com	Residencial Los Álamos	t
CL196	Laura Isabel Méndez	87654336	laura.mendez@gmail.com	Barrio San Miguel	t
CL197	Andrés Felipe Herrera	76543233	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL198	Claudia Patricia Rojas	65432202	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL199	Fernando Antonio Cruz	54321891	fernando.cruz@gmail.com	Barrio La Esperanza	t
CL200	Sofía Alejandra Soto	43218780	sofia.soto@gmail.com	Colonia Los Cedros	t
CL201	Diego Armando García	32187669	diego.garcia@outlook.com	Residencial Las Palmas	t
CL202	Valeria Carolina Pérez	21098780	valeria.perez@gmail.com	Barrio El Carmen	t
CL203	Juan Pablo Ramírez	19876558	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL205	Daniel Esteban Morales	87654337	daniel.morales@gmail.com	Barrio La Unión	t
CL206	Carolina Beatriz Méndez	76543234	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL207	José Antonio Herrera	65432203	jose.herrera@hotmail.com	Residencial El Sol	t
CL208	Mariana Isabel Rojas	54321892	mariana.rojas@yahoo.com	Barrio San Rafael	t
CL209	Luis Fernando Cruz	43218781	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL210	Andrea Patricia Soto	32187670	andrea.soto@gmail.com	Residencial La Luz	t
CL211	Francisco Javier García	21098781	francisco.garcia@gmail.com	Barrio La Paz	t
CL212	Isabel Cristina Pérez	19876559	isabel.perez@hotmail.com	Colonia El Jardín	t
CL213	Pedro Alejandro Ramírez	98765448	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL214	Lucía Fernanda Torres	87654338	lucia.torres@gmail.com	Colonia San Juan	t
CL215	Martín Eduardo Morales	76543235	martin.morales@outlook.com	Colonia Los Laureles	t
CL216	Daniela Alejandra Méndez	65432204	daniela.mendez@gmail.com	Residencial El Prado	t
CL217	José Manuel Herrera	54321893	jose.herrera@hotmail.com	Barrio La Merced	t
CL218	María Isabel Rojas	43218782	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL219	Juan Carlos Cruz	32187671	juan.cruz@gmail.com	Residencial Los Álamos	t
CL220	Paula Andrea Soto	21098782	paula.soto@gmail.com	Barrio San Miguel	t
CL221	Roberto Carlos Sánchez	19876560	roberto.sanchez@gmail.com	Colonia Las Acacias	t
CL222	Elena Patricia López	98765449	elena.lopez@hotmail.com	Residencial El Prado	t
CL223	Oscar Eduardo Gómez	87654339	oscar.gomez@yahoo.com	Barrio La Merced	t
CL224	María Fernanda Torres	76543236	maria.torres@gmail.com	Colonia El Paraíso	t
CL225	José Luis Morales	65432205	jose.morales@outlook.com	Residencial Los Álamos	t
CL226	Laura Isabel Méndez	54321894	laura.mendez@gmail.com	Barrio San Miguel	t
CL227	Andrés Felipe Herrera	43218783	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL228	Claudia Patricia Rojas	32187672	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL229	Fernando Antonio Cruz	21098783	fernando.cruz@gmail.com	Barrio La Esperanza	t
CL230	Sofía Alejandra Soto	19876561	sofia.soto@gmail.com	Colonia Los Cedros	t
CL231	Diego Armando García	98765450	diego.garcia@outlook.com	Residencial Las Palmas	t
CL232	Valeria Carolina Pérez	87654340	valeria.perez@gmail.com	Barrio El Carmen	t
CL233	Juan Pablo Ramírez	76543237	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL234	Paola Andrea Torres	65432206	paola.torres@yahoo.com	Residencial Los Robles	t
CL235	Daniel Esteban Morales	54321895	daniel.morales@gmail.com	Barrio La Unión	t
CL236	Carolina Beatriz Méndez	43218784	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL237	José Antonio Herrera	32187673	jose.herrera@hotmail.com	Residencial El Sol	t
CL239	Luis Fernando Cruz	19876562	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL240	Andrea Patricia Soto	98765451	andrea.soto@gmail.com	Residencial La Luz	t
CL241	Francisco Javier García	87654341	francisco.garcia@gmail.com	Barrio La Paz	t
CL242	Isabel Cristina Pérez	76543238	isabel.perez@hotmail.com	Colonia El Jardín	t
CL243	Pedro Alejandro Ramírez	65432207	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL244	Lucía Fernanda Torres	54321896	lucia.torres@gmail.com	Colonia San Juan	t
CL245	Martín Eduardo Morales	43218785	martin.morales@outlook.com	Colonia Los Laureles	t
CL246	Daniela Alejandra Méndez	32187674	daniela.mendez@gmail.com	Residencial El Prado	t
CL247	José Manuel Herrera	21098785	jose.herrera@hotmail.com	Barrio La Merced	t
CL248	María Isabel Rojas	19876563	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL249	Juan Carlos Cruz	98765452	juan.cruz@gmail.com	Residencial Los Álamos	t
CL250	Paula Andrea Soto	87654342	paula.soto@gmail.com	Barrio San Miguel	t
CL251	Roberto Carlos Sánchez	76543239	roberto.sanchez@gmail.com	Colonia Las Acacias	t
CL252	Elena Patricia López	65432208	elena.lopez@hotmail.com	Residencial El Prado	t
CL253	Oscar Eduardo Gómez	54321897	oscar.gomez@yahoo.com	Barrio La Merced	t
CL254	María Fernanda Torres	43218786	maria.torres@gmail.com	Colonia El Paraíso	t
CL255	José Luis Morales	32187675	jose.morales@outlook.com	Residencial Los Álamos	t
CL256	Laura Isabel Méndez	21098786	laura.mendez@gmail.com	Barrio San Miguel	t
CL257	Andrés Felipe Herrera	19876564	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL258	Claudia Patricia Rojas	98765453	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL260	Sofía Alejandra Soto	76543240	sofia.soto@gmail.com	Colonia Los Cedros	t
CL261	Diego Armando García	65432209	diego.garcia@outlook.com	Residencial Las Palmas	t
CL262	Valeria Carolina Pérez	54321898	valeria.perez@gmail.com	Barrio El Carmen	t
CL238	Mariana Isabel Rojas	21098784	mariana.rojas@yahoo.com	Barrio San Rafael	f
CL204	Paola Andrea Torres	98765447	paola.torres@yahoo.com	Residencial Los Robles	f
CL193	Oscar Eduardo Gómez	21098779	oscar.gomez@yahoo.com	Barrio La Merced	f
CL263	Juan Pablo Ramírez	43218787	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL264	Paola Andrea Torres	32187676	paola.torres@yahoo.com	Residencial Los Robles	t
CL265	Daniel Esteban Morales	21098787	daniel.morales@gmail.com	Barrio La Unión	t
CL266	Carolina Beatriz Méndez	19876565	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL267	José Antonio Herrera	98765454	jose.herrera@hotmail.com	Residencial El Sol	t
CL268	Mariana Isabel Rojas	87654344	mariana.rojas@yahoo.com	Barrio San Rafael	t
CL269	Luis Fernando Cruz	76543241	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL270	Andrea Patricia Soto	65432210	andrea.soto@gmail.com	Residencial La Luz	t
CL271	Francisco Javier García	54321899	francisco.garcia@gmail.com	Barrio La Paz	t
CL272	Isabel Cristina Pérez	43218788	isabel.perez@hotmail.com	Colonia El Jardín	t
CL273	Pedro Alejandro Ramírez	32187677	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL274	Lucía Fernanda Torres	21098788	lucia.torres@gmail.com	Colonia San Juan	t
CL275	Martín Eduardo Morales	19876566	martin.morales@outlook.com	Colonia Los Laureles	t
CL276	Daniela Alejandra Méndez	98765455	daniela.mendez@gmail.com	Residencial El Prado	t
CL277	José Manuel Herrera	87654345	jose.herrera@hotmail.com	Barrio La Merced	t
CL278	María Isabel Rojas	76543242	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL279	Juan Carlos Cruz	65432211	juan.cruz@gmail.com	Residencial Los Álamos	t
CL280	Paula Andrea Soto	54321900	paula.soto@gmail.com	Barrio San Miguel	t
CL282	Elena Patricia López	32187678	elena.lopez@hotmail.com	Residencial El Prado	t
CL283	Oscar Eduardo Gómez	21098789	oscar.gomez@yahoo.com	Barrio La Merced	t
CL284	María Fernanda Torres	19876567	maria.torres@gmail.com	Colonia El Paraíso	t
CL285	José Luis Morales	98765456	jose.morales@outlook.com	Residencial Los Álamos	t
CL286	Laura Isabel Méndez	87654346	laura.mendez@gmail.com	Barrio San Miguel	t
CL287	Andrés Felipe Herrera	76543243	andres.herrera@hotmail.com	Colonia Las Acacias	t
CL288	Claudia Patricia Rojas	65432212	claudia.rojas@yahoo.com	Residencial El Bosque	t
CL289	Fernando Antonio Cruz	54321901	fernando.cruz@gmail.com	Barrio La Esperanza	t
CL290	Sofía Alejandra Soto	43218790	sofia.soto@gmail.com	Colonia Los Cedros	t
CL291	Diego Armando García	32187679	diego.garcia@outlook.com	Residencial Las Palmas	t
CL292	Valeria Carolina Pérez	21098790	valeria.perez@gmail.com	Barrio El Carmen	t
CL293	Juan Pablo Ramírez	19876568	juan.ramirez@hotmail.com	Colonia San Antonio	t
CL294	Paola Andrea Torres	98765457	paola.torres@yahoo.com	Residencial Los Robles	t
CL295	Daniel Esteban Morales	87654347	daniel.morales@gmail.com	Barrio La Unión	t
CL296	Carolina Beatriz Méndez	76543244	carolina.mendez@gmail.com	Colonia Las Margaritas	t
CL297	José Antonio Herrera	65432213	jose.herrera@hotmail.com	Residencial El Sol	t
CL298	Mariana Isabel Rojas	54321902	mariana.rojas@yahoo.com	Barrio San Rafael	t
CL299	Luis Fernando Cruz	43218791	luis.cruz@gmail.com	Colonia Los Ángeles	t
CL300	Andrea Patricia Soto	32187680	andrea.soto@gmail.com	Residencial La Luz	t
CL301	Francisco Javier García	21098791	francisco.garcia@gmail.com	Barrio La Paz	t
CL302	Isabel Cristina Pérez	19876569	isabel.perez@hotmail.com	Colonia El Jardín	t
CL303	Pedro Alejandro Ramírez	98765458	pedro.ramirez@yahoo.com	Residencial Las Rosas	t
CL304	Lucía Fernanda Torres	87654348	lucia.torres@gmail.com	Colonia San Juan	t
CL305	Martín Eduardo Morales	76543245	martin.morales@outlook.com	Colonia Los Laureles	t
CL306	Daniela Alejandra Méndez	65432214	daniela.mendez@gmail.com	Residencial El Prado	t
CL307	José Manuel Herrera	54321903	jose.herrera@hotmail.com	Barrio La Merced	t
CL308	María Isabel Rojas	43218792	maria.rojas@yahoo.com	Colonia El Paraíso	t
CL309	Juan Carlos Cruz	32187681	juan.cruz@gmail.com	Residencial Los Álamos	t
CL310	Paula Andrea Soto	21098792	paula.soto@gmail.com	Barrio San Miguel	t
CL281	Roberto Carlos Sánchez	43218789	roberto.sanchez@gmail.com	Colonia Las Acacias	f
CL259	Fernando Antonio Cruz	87654343	fernando.cruz@gmail.com	Barrio La Esperanza	f
CL151	Francisco Javier García	87654331	francisco.garcia@gmail.com	Barrio La Paz	f
CL311	Cesar Amilkar	92341241	test@example.com	sdfdsafsaf	t
CL312	string	string	string	string	t
CL313	Arleth Oseguera	97283281	arlethoseg14ao@gmail.com	Casa	t
\.


--
-- Data for Name: detalle_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.detalle_pedido (detalle_pedido_id, pedido_id, producto_id, cantidad, precio_unitario, nota) FROM stdin;
DTP00144	250112-PDD069	TAZ	1	200.00	\N
DTP00145	250112-PDD070	TAZ	4	200.00	\N
DTP00149	250112-PDD072	GOR	2	150.00	\N
DTP00150	250112-PDD072	GOR	4	150.00	\N
DTP00011	250101-PDD006	GOR	1	150.00	\N
DTP00012	250101-PDD007	LLA	3	120.00	\N
DTP00013	250101-PDD007	GOR	1	150.00	\N
DTP00153	250113-PDD074	CAM	1	150.00	\N
DTP00154	250113-PDD074	GOR	1	150.00	\N
DTP00160	250113-PDD077	LLA	3	120.00	\N
DTP00161	250113-PDD077	CAM	1	150.00	\N
DTP00014	250101-PDD007	GOR	4	150.00	\N
DTP00015	250102-PDD008	TAZ	1	200.00	\N
DTP00016	250102-PDD008	LLA	2	120.00	\N
DTP00017	250102-PDD009	TAZ	3	200.00	\N
DTP00131	250111-PDD063	GOR	2	150.00	\N
DTP00132	250111-PDD063	TAZ	4	200.00	\N
DTP00133	250111-PDD064	GOR	3	150.00	\N
DTP00134	250111-PDD064	TAZ	1	150.00	\N
DTP00136	250111-PDD065	LLA	4	100.00	\N
DTP00138	250111-PDD066	TAZ	4	200.00	\N
DTP00139	250111-PDD067	TAZ	1	200.00	\N
DTP00140	250111-PDD067	GOR	4	150.00	\N
DTP00141	250112-PDD068	LLA	4	150.00	\N
DTP00142	250112-PDD068	GOR	4	150.00	\N
DTP00162	250113-PDD078	LLA	1	100.00	\N
DTP00163	250113-PDD078	TAZ	2	200.00	\N
DTP00164	250113-PDD078	LLA	1	100.00	\N
DTP00165	250113-PDD079	TAZ	1	200.00	\N
DTP00166	250113-PDD079	TER	2	290.00	\N
DTP00167	250113-PDD079	TAZ	1	200.00	\N
DTP00168	250114-PDD080	GOR	3	150.00	\N
DTP00169	250114-PDD081	LLA	3	150.00	\N
DTP00199	250117-PDD098	CAM	3	200.00	\N
DTP00200	250117-PDD098	TAZ	2	150.00	\N
DTP00201	250117-PDD099	TAZ	3	200.00	\N
DTP00202	250117-PDD099	CAM	4	200.00	\N
DTP00203	250117-PDD099	CAM	1	150.00	\N
DTP00204	250117-PDD100	GOR	3	150.00	\N
DTP00205	250117-PDD101	CAM	2	150.00	\N
DTP00206	250117-PDD101	GOR	2	150.00	\N
DTP00207	250117-PDD102	GOR	2	150.00	\N
DTP00208	250117-PDD102	LLA	3	100.00	\N
DTP00209	250117-PDD103	GOR	4	150.00	\N
DTP00210	250118-PDD104	GOR	4	150.00	\N
DTP00211	250118-PDD104	TAZ	1	200.00	\N
DTP00212	250118-PDD104	GOR	1	150.00	\N
DTP00213	250118-PDD105	GOR	1	150.00	\N
DTP00214	250118-PDD105	TAZ	3	150.00	\N
DTP00215	250118-PDD106	GOR	2	150.00	\N
DTP00216	250118-PDD106	TAZ	3	150.00	\N
DTP00119	250110-PDD056	GOR	2	150.00	\N
DTP00120	250110-PDD056	TER	3	290.00	\N
DTP00121	250110-PDD056	TAZ	4	200.00	\N
DTP00122	250110-PDD057	CAM	3	200.00	\N
DTP00123	250110-PDD058	LLA	3	100.00	\N
DTP00124	250110-PDD058	CAM	4	200.00	\N
DTP00125	250110-PDD059	LLA	4	120.00	\N
DTP00126	250110-PDD059	GOR	3	150.00	\N
DTP00127	250110-PDD060	TAZ	1	200.00	\N
DTP00128	250110-PDD061	GOR	3	150.00	\N
DTP00129	250111-PDD062	GOR	3	150.00	\N
DTP00130	250111-PDD062	CAM	3	150.00	\N
DTP00135	250111-PDD064	CAM	4	150.00	\N
DTP00137	250111-PDD066	CAM	4	200.00	\N
DTP00143	250112-PDD069	CAM	2	150.00	\N
DTP00146	250112-PDD070	TAZ	4	150.00	\N
DTP00147	250112-PDD070	TAZ	4	150.00	\N
DTP00148	250112-PDD071	CAM	4	150.00	\N
DTP00151	250112-PDD073	TAZ	2	150.00	\N
DTP00152	250112-PDD073	TAZ	2	200.00	\N
DTP00178	250114-PDD085	LLA	1	100.00	\N
DTP00179	250114-PDD085	GOR	1	150.00	\N
DTP00180	250115-PDD086	TER	4	290.00	\N
DTP00181	250115-PDD087	GOR	1	150.00	\N
DTP00182	250115-PDD088	TAZ	3	150.00	\N
DTP00183	250115-PDD089	TAZ	3	200.00	\N
DTP00184	250115-PDD090	GOR	1	150.00	\N
DTP00185	250115-PDD090	GOR	1	150.00	\N
DTP00186	250115-PDD091	CAM	4	150.00	\N
DTP00187	250116-PDD092	TAZ	4	150.00	\N
DTP00188	250116-PDD092	GOR	4	150.00	\N
DTP00189	250116-PDD093	CAM	4	150.00	\N
DTP00190	250116-PDD093	TAZ	2	150.00	\N
DTP00191	250116-PDD094	TAZ	1	150.00	\N
DTP00192	250116-PDD095	GOR	1	150.00	\N
DTP00193	250116-PDD095	GOR	2	150.00	\N
DTP00194	250116-PDD096	TAZ	4	200.00	\N
DTP00195	250116-PDD096	TAZ	2	150.00	\N
DTP00196	250116-PDD096	CAM	3	150.00	\N
DTP00197	250116-PDD097	LLA	2	100.00	\N
DTP00198	250117-PDD098	TER	1	170.00	\N
DTP00217	250118-PDD107	TAZ	2	200.00	\N
DTP00218	250118-PDD108	LLA	4	150.00	\N
DTP00219	250118-PDD108	TAZ	4	200.00	\N
DTP00220	250118-PDD109	GOR	3	150.00	\N
DTP00221	250119-PDD110	CAM	2	200.00	\N
DTP00222	250119-PDD110	TAZ	2	150.00	\N
DTP00223	250119-PDD111	CAM	1	200.00	\N
DTP00224	250119-PDD112	TAZ	4	200.00	\N
DTP00225	250119-PDD112	CAM	4	200.00	\N
DTP00226	250119-PDD112	CAM	3	150.00	\N
DTP00227	250119-PDD113	TAZ	3	200.00	\N
DTP00228	250119-PDD114	CAM	2	200.00	\N
DTP00229	250119-PDD115	TAZ	4	150.00	\N
DTP00230	250119-PDD115	GOR	2	150.00	\N
DTP00231	250119-PDD115	TAZ	1	200.00	\N
DTP00232	250120-PDD116	GOR	4	150.00	\N
DTP00233	250120-PDD116	CAM	3	200.00	\N
DTP00234	250120-PDD117	TER	1	170.00	\N
DTP00235	250120-PDD118	TER	4	290.00	\N
DTP00236	250120-PDD118	GOR	4	150.00	\N
DTP00237	250120-PDD118	CAM	4	150.00	\N
DTP00238	250120-PDD119	GOR	3	150.00	\N
DTP00239	250120-PDD120	TAZ	3	200.00	\N
DTP00240	250120-PDD121	CAM	4	200.00	\N
DTP00241	250120-PDD121	LLA	1	120.00	\N
DTP00242	250121-PDD122	TAZ	2	200.00	\N
DTP00243	250121-PDD122	LLA	2	150.00	\N
DTP00244	250121-PDD123	GOR	1	150.00	\N
DTP00245	250121-PDD123	LLA	4	100.00	\N
DTP00246	250121-PDD124	TAZ	4	150.00	\N
DTP00247	250121-PDD124	TAZ	1	200.00	\N
DTP00248	250121-PDD125	LLA	1	100.00	\N
DTP00249	250121-PDD125	TER	2	290.00	\N
DTP00250	250121-PDD125	CAM	1	150.00	\N
DTP00251	250121-PDD126	TAZ	3	200.00	\N
DTP00252	250121-PDD126	TER	3	290.00	\N
DTP00253	250121-PDD127	GOR	1	150.00	\N
DTP00254	250122-PDD128	TAZ	1	150.00	\N
DTP00255	250122-PDD128	TER	2	290.00	\N
DTP00256	250122-PDD128	TAZ	1	200.00	\N
DTP00257	250122-PDD129	TAZ	3	200.00	\N
DTP00301	250125-PDD151	GOR	4	150.00	\N
DTP00302	250125-PDD151	GOR	1	150.00	\N
DTP00303	250126-PDD152	CAM	2	150.00	\N
DTP00304	250126-PDD152	LLA	4	120.00	\N
DTP00305	250126-PDD153	GOR	3	150.00	\N
DTP00306	250126-PDD153	GOR	4	150.00	\N
DTP00307	250126-PDD154	GOR	3	150.00	\N
DTP00308	250126-PDD154	GOR	3	150.00	\N
DTP00309	250126-PDD154	TAZ	1	200.00	\N
DTP00310	250126-PDD155	CAM	4	200.00	\N
DTP00311	250126-PDD155	GOR	3	150.00	\N
DTP00312	250126-PDD156	TAZ	3	150.00	\N
DTP00313	250126-PDD156	LLA	4	150.00	\N
DTP00001	250101-PDD002	CAM	2	200.00	\N
DTP00002	250101-PDD002	GOR	3	150.00	\N
DTP00003	250101-PDD002	GOR	3	150.00	\N
DTP00004	250101-PDD003	GOR	1	150.00	\N
DTP00005	250101-PDD003	GOR	3	150.00	\N
DTP00006	250101-PDD003	GOR	4	150.00	\N
DTP00007	250101-PDD004	LLA	2	100.00	\N
DTP00008	250101-PDD005	LLA	1	100.00	\N
DTP00009	250101-PDD006	GOR	3	150.00	\N
DTP00010	250101-PDD006	LLA	1	100.00	\N
DTP00018	250102-PDD009	TAZ	2	200.00	\N
DTP00019	250102-PDD010	CAM	4	150.00	\N
DTP00025	250102-PDD013	GOR	3	150.00	\N
DTP00026	250102-PDD013	GOR	4	150.00	\N
DTP00027	250103-PDD014	GOR	2	150.00	\N
DTP00028	250103-PDD014	TAZ	4	200.00	\N
DTP00029	250103-PDD014	TER	1	290.00	\N
DTP00030	250103-PDD015	GOR	4	150.00	\N
DTP00031	250103-PDD015	LLA	1	120.00	\N
DTP00032	250103-PDD016	GOR	4	150.00	\N
DTP00033	250103-PDD016	TAZ	3	200.00	\N
DTP00034	250103-PDD017	TAZ	4	150.00	\N
DTP00035	250103-PDD017	GOR	4	150.00	\N
DTP00036	250103-PDD018	TAZ	2	200.00	\N
DTP00037	250103-PDD018	GOR	1	150.00	\N
DTP00038	250103-PDD019	LLA	4	100.00	\N
DTP00039	250103-PDD019	GOR	1	150.00	\N
DTP00040	250104-PDD020	GOR	1	150.00	\N
DTP00041	250104-PDD020	TAZ	1	150.00	\N
DTP00042	250104-PDD020	CAM	4	150.00	\N
DTP00043	250104-PDD021	TAZ	4	200.00	\N
DTP00044	250104-PDD021	GOR	1	150.00	\N
DTP00045	250104-PDD021	GOR	2	150.00	\N
DTP00046	250104-PDD022	CAM	4	150.00	\N
DTP00047	250104-PDD022	GOR	4	150.00	\N
DTP00048	250104-PDD022	TAZ	1	200.00	\N
DTP00023	250102-PDD012	LLA	3	150.00	\N
DTP00049	250104-PDD023	LLA	3	120.00	\N
DTP00050	250104-PDD023	CAM	3	150.00	\N
DTP00024	250102-PDD013	GOR	1	150.00	\N
DTP00051	250104-PDD023	LLA	4	100.00	\N
DTP00052	250104-PDD024	LLA	3	100.00	\N
DTP00053	250104-PDD025	GOR	4	150.00	\N
DTP00054	250105-PDD026	TAZ	2	200.00	\N
DTP00155	250113-PDD075	CAM	2	150.00	\N
DTP00156	250113-PDD075	LLA	3	150.00	\N
DTP00157	250113-PDD076	CAM	3	150.00	\N
DTP00158	250113-PDD076	GOR	2	150.00	\N
DTP00159	250113-PDD076	GOR	2	150.00	\N
DTP00074	250106-PDD037	CAM	1	150.00	\N
DTP00076	250107-PDD038	CAM	1	200.00	\N
DTP00079	250107-PDD039	GOR	2	150.00	\N
DTP00080	250107-PDD039	GOR	4	150.00	\N
DTP00061	250105-PDD029	CAM	4	200.00	\N
DTP00064	250105-PDD031	GOR	3	150.00	\N
DTP00065	250105-PDD031	GOR	1	150.00	\N
DTP00066	250106-PDD032	GOR	4	150.00	\N
DTP00082	250107-PDD040	CAM	3	150.00	\N
DTP00085	250107-PDD042	CAM	1	150.00	\N
DTP00088	250107-PDD043	GOR	3	150.00	\N
DTP00067	250106-PDD033	CAM	3	200.00	\N
DTP00090	250108-PDD044	GOR	1	150.00	\N
DTP00068	250106-PDD033	GOR	4	150.00	\N
DTP00069	250106-PDD034	CAM	2	150.00	\N
DTP00070	250106-PDD034	GOR	3	150.00	\N
DTP00072	250106-PDD035	CAM	3	150.00	\N
DTP00073	250106-PDD036	CAM	3	200.00	\N
DTP00094	250108-PDD046	CAM	1	150.00	\N
DTP00095	250108-PDD046	TAZ	1	150.00	\N
DTP00096	250108-PDD046	TAZ	1	150.00	\N
DTP00097	250108-PDD047	CAM	4	200.00	\N
DTP00098	250108-PDD047	TAZ	4	200.00	\N
DTP00099	250108-PDD047	TER	4	170.00	\N
DTP00100	250108-PDD048	CAM	3	150.00	\N
DTP00101	250108-PDD049	TAZ	1	200.00	\N
DTP00102	250108-PDD049	GOR	2	150.00	\N
DTP00103	250108-PDD049	CAM	2	200.00	\N
DTP00170	250114-PDD081	TER	3	290.00	\N
DTP00171	250114-PDD081	TAZ	1	200.00	\N
DTP00172	250114-PDD082	TAZ	3	200.00	\N
DTP00173	250114-PDD082	TAZ	4	200.00	\N
DTP00174	250114-PDD083	GOR	2	150.00	\N
DTP00175	250114-PDD084	CAM	4	150.00	\N
DTP00176	250114-PDD084	TAZ	3	150.00	\N
DTP00177	250114-PDD085	TAZ	4	200.00	\N
DTP00056	250105-PDD027	CAM	2	200.00	\N
DTP00057	250105-PDD027	TAZ	3	200.00	\N
DTP00058	250105-PDD028	CAM	2	200.00	\N
DTP00059	250105-PDD028	CAM	1	150.00	\N
DTP00060	250105-PDD028	CAM	2	150.00	\N
DTP00062	250105-PDD030	LLA	2	150.00	\N
DTP00063	250105-PDD031	LLA	4	150.00	\N
DTP00071	250106-PDD034	TAZ	3	150.00	\N
DTP00075	250106-PDD037	LLA	3	120.00	\N
DTP00077	250107-PDD038	TAZ	4	150.00	\N
DTP00078	250107-PDD039	LLA	3	100.00	\N
DTP00081	250107-PDD040	TAZ	1	150.00	\N
DTP00083	250107-PDD040	TAZ	3	200.00	\N
DTP00084	250107-PDD041	LLA	3	150.00	\N
DTP00086	250107-PDD043	LLA	1	120.00	\N
DTP00087	250107-PDD043	TAZ	1	200.00	\N
DTP00089	250108-PDD044	TAZ	1	150.00	\N
DTP00091	250108-PDD044	TAZ	3	200.00	\N
DTP00020	250102-PDD010	TAZ	2	200.00	\N
DTP00021	250102-PDD011	CAM	2	150.00	\N
DTP00022	250102-PDD011	TER	3	290.00	\N
DTP00055	250105-PDD027	TER	3	170.00	\N
DTP00092	250108-PDD045	TAZ	1	200.00	\N
DTP00093	250108-PDD045	TAZ	2	150.00	\N
DTP00104	250109-PDD050	GOR	1	150.00	\N
DTP00105	250109-PDD050	LLA	3	120.00	\N
DTP00106	250109-PDD050	CAM	4	200.00	\N
DTP00107	250109-PDD051	GOR	3	150.00	\N
DTP00108	250109-PDD051	GOR	2	150.00	\N
DTP00109	250109-PDD051	LLA	3	100.00	\N
DTP00110	250109-PDD052	CAM	2	150.00	\N
DTP00111	250109-PDD052	GOR	2	150.00	\N
DTP00112	250109-PDD052	CAM	1	200.00	\N
DTP00113	250109-PDD053	LLA	1	100.00	\N
DTP00114	250109-PDD053	GOR	3	150.00	\N
DTP00115	250109-PDD054	GOR	2	150.00	\N
DTP00116	250109-PDD055	TAZ	2	150.00	\N
DTP00117	250109-PDD055	GOR	1	150.00	\N
DTP00118	250109-PDD055	TAZ	3	150.00	\N
DTP00314	250126-PDD157	GOR	1	150.00	\N
DTP00315	250126-PDD157	GOR	2	150.00	\N
DTP00316	250126-PDD157	CAM	2	200.00	\N
DTP00317	250127-PDD158	CAM	4	200.00	\N
DTP00318	250127-PDD158	CAM	1	200.00	\N
DTP00319	250127-PDD158	GOR	3	150.00	\N
DTP00320	250127-PDD159	TAZ	3	200.00	\N
DTP00321	250127-PDD159	TAZ	3	150.00	\N
DTP00322	250127-PDD159	TAZ	3	200.00	\N
DTP00323	250127-PDD160	TAZ	2	200.00	\N
DTP00324	250127-PDD160	LLA	1	150.00	\N
DTP00325	250127-PDD160	TAZ	3	150.00	\N
DTP00326	250127-PDD161	GOR	1	150.00	\N
DTP00327	250127-PDD162	GOR	3	150.00	\N
DTP00328	250127-PDD162	TAZ	3	200.00	\N
DTP00329	250127-PDD163	GOR	2	150.00	\N
DTP00258	250122-PDD129	CAM	1	150.00	\N
DTP00259	250122-PDD130	LLA	4	100.00	\N
DTP00260	250122-PDD130	GOR	1	150.00	\N
DTP00261	250122-PDD130	CAM	1	150.00	\N
DTP00262	250122-PDD131	CAM	3	150.00	\N
DTP00263	250122-PDD132	GOR	3	150.00	\N
DTP00264	250122-PDD133	CAM	3	150.00	\N
DTP00265	250122-PDD133	GOR	4	150.00	\N
DTP00266	250123-PDD134	GOR	3	150.00	\N
DTP00267	250123-PDD134	TAZ	4	200.00	\N
DTP00268	250123-PDD134	LLA	3	100.00	\N
DTP00269	250123-PDD135	TAZ	4	200.00	\N
DTP00270	250123-PDD136	CAM	4	150.00	\N
DTP00271	250123-PDD137	TAZ	1	150.00	\N
DTP00272	250123-PDD137	CAM	2	200.00	\N
DTP00273	250123-PDD138	LLA	1	120.00	\N
DTP00274	250123-PDD138	GOR	3	150.00	\N
DTP00275	250123-PDD139	LLA	3	150.00	\N
DTP00276	250124-PDD140	CAM	3	150.00	\N
DTP00277	250124-PDD140	CAM	1	200.00	\N
DTP00278	250124-PDD140	GOR	2	150.00	\N
DTP00279	250124-PDD141	TAZ	4	200.00	\N
DTP00280	250124-PDD141	LLA	1	120.00	\N
DTP00281	250124-PDD141	GOR	2	150.00	\N
DTP00282	250124-PDD142	GOR	1	150.00	\N
DTP00283	250124-PDD143	TAZ	1	200.00	\N
DTP00284	250124-PDD143	TAZ	4	150.00	\N
DTP00285	250124-PDD144	GOR	3	150.00	\N
DTP00286	250124-PDD145	GOR	1	150.00	\N
DTP00287	250124-PDD145	CAM	4	200.00	\N
DTP00288	250124-PDD145	TER	4	170.00	\N
DTP00289	250125-PDD146	GOR	3	150.00	\N
DTP00290	250125-PDD146	CAM	4	150.00	\N
DTP00291	250125-PDD146	CAM	4	200.00	\N
DTP00292	250125-PDD147	GOR	1	150.00	\N
DTP00293	250125-PDD147	TAZ	2	150.00	\N
DTP00294	250125-PDD148	LLA	2	100.00	\N
DTP00295	250125-PDD148	TAZ	1	200.00	\N
DTP00296	250125-PDD148	GOR	4	150.00	\N
DTP00297	250125-PDD149	GOR	2	150.00	\N
DTP00298	250125-PDD149	LLA	4	120.00	\N
DTP00299	250125-PDD149	TAZ	1	200.00	\N
DTP00300	250125-PDD150	CAM	4	150.00	\N
DTP00330	250127-PDD163	LLA	1	150.00	\N
DTP00331	250128-PDD164	GOR	3	150.00	\N
DTP00332	250128-PDD165	GOR	3	150.00	\N
DTP00333	250128-PDD165	TAZ	2	150.00	\N
DTP00334	250128-PDD165	CAM	3	150.00	\N
DTP00335	250128-PDD166	TAZ	4	200.00	\N
DTP00336	250128-PDD166	LLA	2	120.00	\N
DTP00337	250128-PDD166	GOR	3	150.00	\N
DTP00338	250128-PDD167	TAZ	2	200.00	\N
DTP00339	250128-PDD167	CAM	3	150.00	\N
DTP00340	250128-PDD168	TAZ	4	150.00	\N
DTP00341	250128-PDD169	CAM	4	150.00	\N
DTP00342	250129-PDD170	TAZ	3	200.00	\N
DTP00343	250129-PDD170	CAM	3	150.00	\N
DTP00344	250129-PDD170	CAM	4	200.00	\N
DTP00345	250129-PDD171	TAZ	2	200.00	\N
DTP00346	250129-PDD171	GOR	1	150.00	\N
DTP00347	250129-PDD171	TAZ	4	200.00	\N
DTP00348	250129-PDD172	GOR	3	150.00	\N
DTP00349	250129-PDD172	GOR	2	150.00	\N
DTP00350	250129-PDD173	TER	4	290.00	\N
DTP00351	250129-PDD174	TAZ	1	150.00	\N
DTP00352	250129-PDD174	LLA	4	150.00	\N
DTP00353	250129-PDD174	CAM	2	200.00	\N
DTP00354	250129-PDD175	TAZ	2	150.00	\N
DTP00355	250129-PDD175	GOR	4	150.00	\N
DTP00356	250130-PDD176	GOR	4	150.00	\N
DTP00357	250130-PDD177	LLA	2	100.00	\N
DTP00358	250130-PDD177	GOR	3	150.00	\N
DTP00359	250130-PDD177	GOR	2	150.00	\N
DTP00360	250130-PDD178	GOR	4	150.00	\N
DTP00361	250130-PDD178	GOR	3	150.00	\N
DTP00362	250130-PDD179	TAZ	2	200.00	\N
DTP00363	250130-PDD179	CAM	3	150.00	\N
DTP00364	250130-PDD180	CAM	4	200.00	\N
DTP00365	250130-PDD181	CAM	2	200.00	\N
DTP00366	250130-PDD181	TAZ	2	200.00	\N
DTP00367	250130-PDD181	TAZ	3	200.00	\N
DTP00368	250131-PDD182	CAM	3	150.00	\N
DTP00369	250131-PDD182	TAZ	2	150.00	\N
DTP00370	250131-PDD182	GOR	2	150.00	\N
DTP00371	250131-PDD183	LLA	1	120.00	\N
DTP00372	250131-PDD183	CAM	1	200.00	\N
DTP00373	250131-PDD184	GOR	2	150.00	\N
DTP00374	250131-PDD184	LLA	2	120.00	\N
DTP00375	250131-PDD184	GOR	4	150.00	\N
DTP00376	250131-PDD185	GOR	2	150.00	\N
DTP00377	250131-PDD185	GOR	2	150.00	\N
DTP00378	250131-PDD185	LLA	2	120.00	\N
DTP00379	250131-PDD186	GOR	3	150.00	\N
DTP00380	250131-PDD187	GOR	3	150.00	\N
DTP00381	250131-PDD187	LLA	1	120.00	\N
DTP00382	250201-PDD188	GOR	4	150.00	\N
DTP00383	250201-PDD189	GOR	4	150.00	\N
DTP00384	250201-PDD190	TAZ	2	200.00	\N
DTP00385	250201-PDD190	GOR	1	150.00	\N
DTP00386	250201-PDD191	GOR	1	150.00	\N
DTP00387	250201-PDD192	CAM	1	200.00	\N
DTP00388	250201-PDD192	TAZ	1	200.00	\N
DTP00389	250201-PDD192	TAZ	4	150.00	\N
DTP00390	250201-PDD193	GOR	3	150.00	\N
DTP00391	250202-PDD194	GOR	4	150.00	\N
DTP00392	250202-PDD195	TAZ	1	150.00	\N
DTP00393	250202-PDD195	CAM	2	200.00	\N
DTP00394	250202-PDD195	LLA	3	150.00	\N
DTP00395	250202-PDD196	TAZ	2	150.00	\N
DTP00396	250202-PDD197	GOR	2	150.00	\N
DTP00397	250202-PDD197	GOR	4	150.00	\N
DTP00398	250202-PDD197	LLA	1	100.00	\N
DTP00399	250202-PDD198	CAM	1	200.00	\N
DTP00400	250202-PDD199	LLA	4	100.00	\N
DTP00401	250202-PDD199	LLA	1	150.00	\N
DTP00402	250203-PDD200	LLA	4	120.00	\N
DTP00403	250203-PDD201	TAZ	2	150.00	\N
DTP00404	250203-PDD201	TER	3	170.00	\N
DTP00405	250203-PDD201	GOR	3	150.00	\N
DTP00406	250203-PDD202	LLA	3	100.00	\N
DTP00407	250203-PDD202	GOR	2	150.00	\N
DTP00408	250203-PDD203	LLA	3	150.00	\N
DTP00409	250203-PDD204	CAM	3	150.00	\N
DTP00410	250203-PDD204	LLA	1	100.00	\N
DTP00411	250203-PDD205	LLA	3	150.00	\N
DTP00412	250203-PDD205	LLA	1	100.00	\N
DTP00413	250203-PDD205	LLA	3	120.00	\N
DTP00414	250204-PDD206	CAM	3	200.00	\N
DTP00415	250204-PDD206	GOR	1	150.00	\N
DTP00416	250204-PDD206	TAZ	2	150.00	\N
DTP00417	250204-PDD207	GOR	2	150.00	\N
DTP00418	250204-PDD207	LLA	3	100.00	\N
DTP00419	250204-PDD208	CAM	3	150.00	\N
DTP00420	250204-PDD209	TAZ	4	150.00	\N
DTP00421	250204-PDD209	CAM	2	200.00	\N
DTP00422	250204-PDD209	GOR	4	150.00	\N
DTP00423	250204-PDD210	TER	1	170.00	\N
DTP00424	250204-PDD211	CAM	1	200.00	\N
DTP00425	250204-PDD211	CAM	2	200.00	\N
DTP00426	250205-PDD212	GOR	2	150.00	\N
DTP00427	250205-PDD212	TAZ	2	200.00	\N
DTP00428	250205-PDD212	GOR	4	150.00	\N
DTP00429	250205-PDD213	CAM	4	150.00	\N
DTP00430	250205-PDD213	TAZ	4	200.00	\N
DTP00431	250205-PDD214	GOR	4	150.00	\N
DTP00432	250205-PDD214	TAZ	3	150.00	\N
DTP00433	250205-PDD214	TAZ	3	150.00	\N
DTP00434	250205-PDD215	GOR	2	150.00	\N
DTP00435	250205-PDD215	CAM	4	150.00	\N
DTP00436	250205-PDD215	LLA	1	100.00	\N
DTP00437	250205-PDD216	LLA	3	150.00	\N
DTP00438	250205-PDD216	GOR	3	150.00	\N
DTP00439	250205-PDD217	CAM	4	150.00	\N
DTP00440	250205-PDD217	GOR	1	150.00	\N
DTP00441	250206-PDD218	GOR	4	150.00	\N
DTP00442	250206-PDD218	CAM	3	200.00	\N
DTP00443	250206-PDD218	TAZ	4	150.00	\N
DTP00444	250206-PDD219	LLA	4	150.00	\N
DTP00445	250206-PDD220	GOR	2	150.00	\N
DTP00446	250206-PDD220	TAZ	2	200.00	\N
DTP00447	250206-PDD221	CAM	4	200.00	\N
DTP00448	250206-PDD221	TAZ	2	150.00	\N
DTP00449	250206-PDD222	TAZ	3	200.00	\N
DTP00450	250206-PDD223	CAM	4	150.00	\N
DTP00451	250206-PDD223	LLA	3	100.00	\N
DTP00452	250206-PDD223	LLA	2	150.00	\N
DTP00453	250207-PDD224	CAM	3	200.00	\N
DTP00454	250207-PDD225	TAZ	1	200.00	\N
DTP00455	250207-PDD225	TAZ	2	200.00	\N
DTP00456	250207-PDD225	GOR	2	150.00	\N
DTP00457	250207-PDD226	TAZ	3	150.00	\N
DTP00458	250207-PDD227	TAZ	1	150.00	\N
DTP00459	250207-PDD228	TAZ	1	150.00	\N
DTP00460	250207-PDD229	GOR	2	150.00	\N
DTP00461	250208-PDD230	TAZ	2	200.00	\N
DTP00462	250208-PDD230	GOR	4	150.00	\N
DTP00463	250208-PDD231	TAZ	2	200.00	\N
DTP00464	250208-PDD232	GOR	4	150.00	\N
DTP00465	250208-PDD232	GOR	4	150.00	\N
DTP00466	250208-PDD233	CAM	2	200.00	\N
DTP00467	250208-PDD234	TAZ	4	200.00	\N
DTP00468	250208-PDD234	CAM	2	200.00	\N
DTP00469	250208-PDD234	GOR	1	150.00	\N
DTP00470	250208-PDD235	LLA	2	120.00	\N
DTP00471	250208-PDD235	CAM	1	200.00	\N
DTP00472	250209-PDD236	CAM	2	200.00	\N
DTP00473	250209-PDD236	CAM	3	150.00	\N
DTP00474	250209-PDD236	CAM	4	150.00	\N
DTP00475	250209-PDD237	LLA	4	100.00	\N
DTP00476	250209-PDD237	GOR	3	150.00	\N
DTP00477	250209-PDD237	GOR	2	150.00	\N
DTP00478	250209-PDD238	CAM	2	200.00	\N
DTP00479	250209-PDD238	TAZ	3	200.00	\N
DTP00480	250209-PDD238	CAM	2	150.00	\N
DTP00481	250209-PDD239	TER	3	170.00	\N
DTP00482	250209-PDD239	GOR	1	150.00	\N
DTP00483	250209-PDD240	TAZ	2	150.00	\N
DTP00484	250209-PDD241	LLA	4	120.00	\N
DTP00485	250209-PDD241	CAM	1	200.00	\N
DTP00486	250210-PDD242	TAZ	1	200.00	\N
DTP00487	250210-PDD243	TAZ	1	150.00	\N
DTP00488	250210-PDD243	GOR	4	150.00	\N
DTP00489	250210-PDD243	GOR	3	150.00	\N
DTP00490	250210-PDD244	LLA	2	120.00	\N
DTP00491	250210-PDD244	GOR	4	150.00	\N
DTP00492	250210-PDD245	CAM	2	200.00	\N
DTP00493	250210-PDD246	GOR	4	150.00	\N
DTP00494	250210-PDD246	TAZ	1	200.00	\N
DTP00495	250210-PDD246	CAM	2	200.00	\N
DTP00496	250210-PDD247	TAZ	4	200.00	\N
DTP00497	250210-PDD247	CAM	4	200.00	\N
DTP00498	250210-PDD247	CAM	3	200.00	\N
DTP00499	250211-PDD248	CAM	2	200.00	\N
DTP00500	250211-PDD249	TAZ	4	200.00	\N
DTP00501	250211-PDD250	GOR	4	150.00	\N
DTP00502	250211-PDD250	TAZ	3	200.00	\N
DTP00503	250211-PDD251	LLA	1	150.00	\N
DTP00504	250211-PDD251	CAM	3	200.00	\N
DTP00505	250211-PDD251	TAZ	3	200.00	\N
DTP00506	250211-PDD252	GOR	1	150.00	\N
DTP00507	250211-PDD252	LLA	4	100.00	\N
DTP00508	250211-PDD252	GOR	3	150.00	\N
DTP00509	250211-PDD253	TAZ	4	150.00	\N
DTP00510	250212-PDD254	LLA	1	120.00	\N
DTP00511	250212-PDD254	CAM	4	200.00	\N
DTP00512	250212-PDD254	TAZ	3	200.00	\N
DTP00513	250212-PDD255	LLA	3	120.00	\N
DTP00514	250212-PDD255	TAZ	2	150.00	\N
DTP00515	250212-PDD256	TAZ	3	200.00	\N
DTP00516	250212-PDD256	CAM	1	150.00	\N
DTP00517	250212-PDD257	GOR	4	150.00	\N
DTP00518	250212-PDD257	TAZ	4	200.00	\N
DTP00519	250212-PDD257	CAM	4	200.00	\N
DTP00520	250212-PDD258	TER	3	170.00	\N
DTP00521	250212-PDD258	CAM	1	200.00	\N
DTP00522	250212-PDD259	LLA	2	100.00	\N
DTP00523	250212-PDD259	CAM	4	150.00	\N
DTP00524	250213-PDD260	GOR	4	150.00	\N
DTP00525	250213-PDD260	GOR	4	150.00	\N
DTP00526	250213-PDD260	LLA	1	120.00	\N
DTP00527	250213-PDD261	TAZ	3	200.00	\N
DTP00528	250213-PDD261	CAM	4	150.00	\N
DTP00529	250213-PDD261	TER	3	170.00	\N
DTP00530	250213-PDD262	TAZ	1	150.00	\N
DTP00531	250213-PDD262	TAZ	2	200.00	\N
DTP00532	250213-PDD263	TAZ	3	200.00	\N
DTP00533	250213-PDD264	TAZ	4	200.00	\N
DTP00534	250213-PDD265	TAZ	1	150.00	\N
DTP00535	250213-PDD265	TAZ	3	200.00	\N
DTP00536	250214-PDD266	CAM	2	200.00	\N
DTP00537	250214-PDD266	GOR	1	150.00	\N
DTP00538	250214-PDD266	TAZ	2	150.00	\N
DTP00539	250214-PDD267	LLA	3	100.00	\N
DTP00540	250214-PDD267	CAM	1	200.00	\N
DTP00541	250214-PDD268	GOR	1	150.00	\N
DTP00542	250214-PDD269	TAZ	2	150.00	\N
DTP00543	250214-PDD269	TAZ	1	150.00	\N
DTP00544	250214-PDD269	LLA	3	100.00	\N
DTP00545	250214-PDD270	GOR	3	150.00	\N
DTP00546	250214-PDD270	GOR	3	150.00	\N
DTP00547	250214-PDD271	CAM	1	200.00	\N
DTP00548	250214-PDD271	GOR	2	150.00	\N
DTP00549	250214-PDD271	GOR	1	150.00	\N
DTP00550	250215-PDD272	CAM	4	200.00	\N
DTP00551	250215-PDD272	LLA	1	150.00	\N
DTP00552	250215-PDD272	CAM	4	200.00	\N
DTP00553	250215-PDD273	LLA	2	120.00	\N
DTP00554	250215-PDD273	CAM	4	150.00	\N
DTP00555	250215-PDD274	TAZ	2	200.00	\N
DTP00556	250215-PDD275	TAZ	4	200.00	\N
DTP00557	250215-PDD275	GOR	1	150.00	\N
DTP00558	250215-PDD276	LLA	3	100.00	\N
DTP00559	250215-PDD276	GOR	4	150.00	\N
DTP00560	250215-PDD276	LLA	1	120.00	\N
DTP00561	250215-PDD277	TAZ	2	200.00	\N
DTP00562	250215-PDD277	CAM	4	150.00	\N
DTP00563	250216-PDD278	LLA	1	150.00	\N
DTP00564	250216-PDD278	CAM	4	150.00	\N
DTP00565	250216-PDD279	TAZ	2	200.00	\N
DTP00566	250216-PDD279	TER	3	170.00	\N
DTP00567	250216-PDD279	LLA	1	100.00	\N
DTP00568	250216-PDD280	GOR	1	150.00	\N
DTP00569	250216-PDD281	TAZ	4	150.00	\N
DTP00570	250216-PDD281	GOR	4	150.00	\N
DTP00571	250216-PDD282	GOR	1	150.00	\N
DTP00572	250216-PDD282	TAZ	4	200.00	\N
DTP00573	250216-PDD282	LLA	4	100.00	\N
DTP00574	250216-PDD283	TAZ	1	200.00	\N
DTP00575	250216-PDD283	CAM	4	200.00	\N
DTP00576	250216-PDD283	CAM	1	150.00	\N
DTP00577	250217-PDD284	LLA	4	120.00	\N
DTP00578	250217-PDD284	LLA	3	120.00	\N
DTP00579	250217-PDD284	CAM	3	200.00	\N
DTP00580	250217-PDD285	TAZ	2	150.00	\N
DTP00581	250217-PDD286	TAZ	1	200.00	\N
DTP00582	250217-PDD286	CAM	2	150.00	\N
DTP00583	250217-PDD286	TAZ	4	150.00	\N
DTP00584	250217-PDD287	GOR	4	150.00	\N
DTP00585	250217-PDD287	GOR	1	150.00	\N
DTP00586	250217-PDD287	TER	2	290.00	\N
DTP00587	250217-PDD288	TAZ	1	200.00	\N
DTP00588	250217-PDD288	GOR	1	150.00	\N
DTP00589	250217-PDD289	TAZ	4	150.00	\N
DTP00590	250217-PDD289	CAM	3	150.00	\N
DTP00591	250217-PDD289	TAZ	2	200.00	\N
DTP00592	250218-PDD290	TAZ	4	200.00	\N
DTP00593	250218-PDD290	GOR	4	150.00	\N
DTP00594	250218-PDD291	TAZ	3	200.00	\N
DTP00595	250218-PDD292	TAZ	1	200.00	\N
DTP00596	250218-PDD293	TAZ	3	150.00	\N
DTP00597	250218-PDD294	TAZ	2	150.00	\N
DTP00598	250218-PDD294	GOR	4	150.00	\N
DTP00599	250218-PDD294	TAZ	4	200.00	\N
DTP00600	250218-PDD295	TAZ	4	150.00	\N
DTP00601	250218-PDD295	LLA	4	100.00	\N
DTP00602	250219-PDD296	LLA	4	100.00	\N
DTP00603	250219-PDD296	CAM	1	200.00	\N
DTP00604	250219-PDD297	GOR	1	150.00	\N
DTP00605	250219-PDD297	GOR	1	150.00	\N
DTP00606	250219-PDD298	CAM	3	150.00	\N
DTP00607	250219-PDD298	GOR	4	150.00	\N
DTP00608	250219-PDD298	CAM	4	200.00	\N
DTP00609	250219-PDD299	TAZ	1	200.00	\N
DTP00610	250219-PDD299	TAZ	4	150.00	\N
DTP00611	250219-PDD300	LLA	3	100.00	\N
DTP00612	250219-PDD300	CAM	3	150.00	\N
DTP00613	250219-PDD301	CAM	4	150.00	\N
DTP00614	250219-PDD301	TAZ	3	150.00	\N
DTP00615	250219-PDD301	TAZ	4	200.00	\N
DTP00616	250220-PDD302	TAZ	2	200.00	\N
DTP00617	250220-PDD303	GOR	1	150.00	\N
DTP00618	250220-PDD303	LLA	4	100.00	\N
DTP00619	250220-PDD304	GOR	1	150.00	\N
DTP00620	250220-PDD304	LLA	4	120.00	\N
DTP00621	250220-PDD305	TAZ	3	150.00	\N
DTP00622	250220-PDD305	GOR	3	150.00	\N
DTP00623	250220-PDD306	CAM	3	150.00	\N
DTP00624	250220-PDD306	TAZ	3	200.00	\N
DTP00625	250220-PDD307	CAM	3	200.00	\N
DTP00626	250220-PDD307	CAM	1	150.00	\N
DTP00627	250220-PDD307	LLA	3	100.00	\N
DTP00628	250221-PDD308	LLA	1	100.00	\N
DTP00629	250221-PDD308	GOR	4	150.00	\N
DTP00630	250221-PDD308	CAM	4	200.00	\N
DTP00631	250221-PDD309	GOR	4	150.00	\N
DTP00632	250221-PDD309	GOR	1	150.00	\N
DTP00633	250221-PDD310	GOR	4	150.00	\N
DTP00634	250221-PDD311	CAM	2	150.00	\N
DTP00635	250221-PDD311	GOR	2	150.00	\N
DTP00636	250221-PDD311	TAZ	2	200.00	\N
DTP00637	250221-PDD312	TAZ	1	200.00	\N
DTP00638	250221-PDD312	LLA	1	150.00	\N
DTP00639	250221-PDD312	TAZ	2	150.00	\N
DTP00640	250221-PDD313	GOR	3	150.00	\N
DTP00641	250222-PDD314	TAZ	3	150.00	\N
DTP00642	250222-PDD315	LLA	2	120.00	\N
DTP00643	250222-PDD315	TAZ	3	150.00	\N
DTP00644	250222-PDD316	CAM	1	150.00	\N
DTP00645	250222-PDD316	TAZ	1	200.00	\N
DTP00646	250222-PDD316	CAM	3	150.00	\N
DTP00647	250222-PDD317	TAZ	4	150.00	\N
DTP00648	250222-PDD317	TAZ	2	150.00	\N
DTP00649	250222-PDD317	TAZ	3	200.00	\N
DTP00650	250222-PDD318	GOR	2	150.00	\N
DTP00651	250222-PDD318	TAZ	3	150.00	\N
DTP00652	250222-PDD318	TER	3	290.00	\N
DTP00653	250222-PDD319	TAZ	2	200.00	\N
DTP00654	250223-PDD320	LLA	3	100.00	\N
DTP00655	250223-PDD320	GOR	2	150.00	\N
DTP00656	250223-PDD320	CAM	3	200.00	\N
DTP00657	250223-PDD321	CAM	4	200.00	\N
DTP00658	250223-PDD321	CAM	1	200.00	\N
DTP00659	250223-PDD322	GOR	4	150.00	\N
DTP00660	250223-PDD322	GOR	3	150.00	\N
DTP00661	250223-PDD322	TAZ	4	150.00	\N
DTP00662	250223-PDD323	CAM	1	200.00	\N
DTP00663	250223-PDD323	GOR	3	150.00	\N
DTP00664	250223-PDD324	CAM	4	200.00	\N
DTP00665	250223-PDD324	GOR	4	150.00	\N
DTP00666	250223-PDD325	GOR	3	150.00	\N
DTP00667	250224-PDD326	GOR	3	150.00	\N
DTP00668	250224-PDD327	GOR	3	150.00	\N
DTP00669	250224-PDD328	CAM	3	200.00	\N
DTP00670	250224-PDD329	TAZ	2	200.00	\N
DTP00671	250224-PDD329	TAZ	1	200.00	\N
DTP00672	250224-PDD329	LLA	3	150.00	\N
DTP00673	250224-PDD330	CAM	1	200.00	\N
DTP00674	250224-PDD331	CAM	1	150.00	\N
DTP00675	250224-PDD331	TER	4	170.00	\N
DTP00676	250224-PDD331	CAM	1	150.00	\N
DTP00677	250225-PDD332	LLA	3	150.00	\N
DTP00678	250225-PDD333	CAM	3	150.00	\N
DTP00679	250225-PDD334	CAM	4	150.00	\N
DTP00680	250225-PDD334	TAZ	2	200.00	\N
DTP00681	250225-PDD335	GOR	2	150.00	\N
DTP00682	250225-PDD335	LLA	3	150.00	\N
DTP00683	250225-PDD336	TAZ	2	150.00	\N
DTP00684	250225-PDD337	TAZ	3	150.00	\N
DTP00685	250226-PDD338	TAZ	4	200.00	\N
DTP00686	250226-PDD339	LLA	3	120.00	\N
DTP00687	250226-PDD340	GOR	2	150.00	\N
DTP00688	250226-PDD341	TAZ	3	150.00	\N
DTP00689	250226-PDD341	GOR	4	150.00	\N
DTP00690	250226-PDD342	LLA	2	120.00	\N
DTP00691	250226-PDD343	CAM	4	200.00	\N
DTP00692	250226-PDD343	GOR	1	150.00	\N
DTP00693	250227-PDD344	TAZ	1	200.00	\N
DTP00694	250227-PDD344	TAZ	4	200.00	\N
DTP00695	250227-PDD345	TAZ	2	200.00	\N
DTP00696	250227-PDD345	CAM	2	150.00	\N
DTP00697	250227-PDD345	LLA	4	100.00	\N
DTP00698	250227-PDD346	TAZ	3	150.00	\N
DTP00699	250227-PDD346	GOR	1	150.00	\N
DTP00700	250227-PDD346	TAZ	1	200.00	\N
DTP00701	250227-PDD347	LLA	1	120.00	\N
DTP00702	250227-PDD347	CAM	2	200.00	\N
DTP00703	250227-PDD347	CAM	2	200.00	\N
DTP00704	250227-PDD348	LLA	4	150.00	\N
DTP00705	250227-PDD349	TAZ	3	150.00	\N
DTP00706	250228-PDD350	GOR	4	150.00	\N
DTP00707	250228-PDD350	CAM	2	200.00	\N
DTP00708	250228-PDD350	TAZ	4	150.00	\N
DTP00709	250228-PDD351	TAZ	3	200.00	\N
DTP00710	250228-PDD352	TAZ	1	200.00	\N
DTP00711	250228-PDD352	TER	2	170.00	\N
DTP00712	250228-PDD353	TAZ	3	150.00	\N
DTP00713	250228-PDD353	GOR	3	150.00	\N
DTP00714	250228-PDD354	CAM	2	200.00	\N
DTP00715	250228-PDD355	GOR	3	150.00	\N
DTP00716	250228-PDD355	GOR	2	150.00	\N
DTP00717	250228-PDD355	TAZ	3	150.00	\N
DTP00718	250301-PDD356	CAM	4	200.00	\N
DTP00719	250301-PDD357	GOR	4	150.00	\N
DTP00720	250301-PDD358	CAM	4	150.00	\N
DTP00721	250301-PDD358	GOR	4	150.00	\N
DTP00722	250301-PDD359	CAM	2	200.00	\N
DTP00723	250301-PDD359	CAM	4	200.00	\N
DTP00724	250301-PDD360	CAM	1	200.00	\N
DTP00725	250301-PDD360	TAZ	1	200.00	\N
DTP00726	250301-PDD361	CAM	1	200.00	\N
DTP00727	250301-PDD361	GOR	2	150.00	\N
DTP00728	250301-PDD361	CAM	3	150.00	\N
DTP00729	250302-PDD362	CAM	4	150.00	\N
DTP00730	250302-PDD363	TAZ	3	150.00	\N
DTP00731	250302-PDD363	LLA	2	100.00	\N
DTP00732	250302-PDD363	LLA	3	120.00	\N
DTP00733	250302-PDD364	CAM	2	150.00	\N
DTP00734	250302-PDD364	LLA	3	100.00	\N
DTP00735	250302-PDD365	TAZ	1	200.00	\N
DTP00736	250302-PDD365	CAM	1	200.00	\N
DTP00737	250302-PDD365	CAM	2	200.00	\N
DTP00738	250302-PDD366	GOR	2	150.00	\N
DTP00739	250302-PDD366	TAZ	3	200.00	\N
DTP00740	250302-PDD367	TAZ	2	200.00	\N
DTP00741	250302-PDD367	LLA	4	100.00	\N
DTP00742	250303-PDD368	TAZ	1	200.00	\N
DTP00743	250303-PDD368	LLA	1	120.00	\N
DTP00744	250303-PDD368	TAZ	1	150.00	\N
DTP00745	250303-PDD369	CAM	4	200.00	\N
DTP00746	250303-PDD369	TER	4	290.00	\N
DTP00747	250303-PDD369	GOR	3	150.00	\N
DTP00748	250303-PDD370	TAZ	2	150.00	\N
DTP00749	250303-PDD370	LLA	4	100.00	\N
DTP00750	250303-PDD370	TAZ	4	150.00	\N
DTP00751	250303-PDD371	CAM	2	200.00	\N
DTP00752	250303-PDD371	GOR	2	150.00	\N
DTP00753	250303-PDD372	LLA	1	100.00	\N
DTP00754	250303-PDD372	GOR	3	150.00	\N
DTP00755	250303-PDD373	CAM	4	150.00	\N
DTP00756	250303-PDD373	GOR	3	150.00	\N
DTP00757	250304-PDD374	TER	4	290.00	\N
DTP00758	250304-PDD375	TAZ	1	200.00	\N
DTP00759	250304-PDD375	GOR	3	150.00	\N
DTP00760	250304-PDD375	GOR	3	150.00	\N
DTP00761	250304-PDD376	LLA	1	150.00	\N
DTP00762	250304-PDD377	GOR	1	150.00	\N
DTP00763	250304-PDD378	GOR	1	150.00	\N
DTP00764	250304-PDD378	LLA	2	120.00	\N
DTP00765	250304-PDD379	CAM	4	150.00	\N
DTP00766	250304-PDD379	GOR	4	150.00	\N
DTP00767	250305-PDD380	GOR	1	150.00	\N
DTP00768	250305-PDD380	GOR	2	150.00	\N
DTP00769	250305-PDD381	TER	4	290.00	\N
DTP00770	250305-PDD382	CAM	4	150.00	\N
DTP00771	250305-PDD383	GOR	4	150.00	\N
DTP00772	250305-PDD383	CAM	3	150.00	\N
DTP00773	250305-PDD384	LLA	3	120.00	\N
DTP00774	250305-PDD384	TAZ	1	150.00	\N
DTP00775	250305-PDD384	TAZ	3	150.00	\N
DTP00776	250305-PDD385	CAM	4	200.00	\N
DTP00777	250305-PDD385	CAM	2	150.00	\N
DTP00778	250306-PDD386	TAZ	3	200.00	\N
DTP00779	250306-PDD386	TER	4	290.00	\N
DTP00780	250306-PDD386	CAM	3	150.00	\N
DTP00781	250306-PDD387	TAZ	1	150.00	\N
DTP00782	250306-PDD387	TAZ	1	200.00	\N
DTP00783	250306-PDD388	GOR	3	150.00	\N
DTP00784	250306-PDD389	CAM	4	200.00	\N
DTP00785	250306-PDD390	GOR	4	150.00	\N
DTP00786	250306-PDD390	GOR	1	150.00	\N
DTP00787	250306-PDD391	TER	3	170.00	\N
DTP00788	250306-PDD391	TAZ	2	150.00	\N
DTP00789	250307-PDD392	TAZ	3	200.00	\N
DTP00790	250307-PDD393	LLA	1	120.00	\N
DTP00791	250307-PDD394	CAM	3	200.00	\N
DTP00792	250307-PDD394	GOR	2	150.00	\N
DTP00793	250307-PDD394	CAM	1	200.00	\N
DTP00794	250307-PDD395	TER	4	170.00	\N
DTP00795	250307-PDD395	LLA	3	150.00	\N
DTP00796	250307-PDD395	LLA	3	150.00	\N
DTP00797	250307-PDD396	CAM	3	200.00	\N
DTP00798	250307-PDD396	LLA	2	120.00	\N
DTP00799	250307-PDD397	LLA	4	120.00	\N
DTP00800	250308-PDD398	LLA	1	100.00	\N
DTP00801	250308-PDD398	TAZ	4	150.00	\N
DTP00802	250308-PDD398	TAZ	4	150.00	\N
DTP00803	250308-PDD399	GOR	4	150.00	\N
DTP00804	250308-PDD399	TER	1	170.00	\N
DTP00805	250308-PDD399	CAM	2	150.00	\N
DTP00806	250308-PDD400	TAZ	2	150.00	\N
DTP00807	250308-PDD400	GOR	4	150.00	\N
DTP00808	250308-PDD401	TAZ	4	150.00	\N
DTP00809	250308-PDD401	LLA	3	100.00	\N
DTP00810	250308-PDD401	GOR	4	150.00	\N
DTP00811	250308-PDD402	TER	3	170.00	\N
DTP00812	250308-PDD403	GOR	1	150.00	\N
DTP00813	250308-PDD403	TAZ	1	150.00	\N
DTP00814	250309-PDD404	LLA	1	150.00	\N
DTP00815	250309-PDD405	CAM	4	150.00	\N
DTP00816	250309-PDD405	TAZ	2	200.00	\N
DTP00817	250309-PDD406	GOR	3	150.00	\N
DTP00818	250309-PDD406	TAZ	3	150.00	\N
DTP00819	250309-PDD406	GOR	1	150.00	\N
DTP00820	250309-PDD407	LLA	1	150.00	\N
DTP00821	250309-PDD407	TAZ	2	150.00	\N
DTP00822	250309-PDD408	GOR	2	150.00	\N
DTP00823	250309-PDD408	LLA	3	120.00	\N
DTP00824	250309-PDD409	GOR	1	150.00	\N
DTP00825	250309-PDD409	GOR	1	150.00	\N
DTP00826	250309-PDD409	CAM	3	150.00	\N
DTP00827	250310-PDD410	CAM	2	150.00	\N
DTP00828	250310-PDD410	GOR	3	150.00	\N
DTP00829	250310-PDD411	GOR	4	150.00	\N
DTP00830	250310-PDD411	TAZ	2	150.00	\N
DTP00831	250310-PDD411	LLA	4	120.00	\N
DTP00832	250310-PDD412	LLA	1	120.00	\N
DTP00833	250310-PDD413	CAM	3	200.00	\N
DTP00834	250310-PDD413	CAM	1	150.00	\N
DTP00835	250310-PDD413	TER	2	170.00	\N
DTP00836	250310-PDD414	TER	4	170.00	\N
DTP00837	250310-PDD414	GOR	2	150.00	\N
DTP00838	250310-PDD415	TAZ	3	150.00	\N
DTP00839	250310-PDD415	LLA	1	150.00	\N
DTP00840	250311-PDD416	LLA	4	150.00	\N
DTP00841	250311-PDD416	GOR	4	150.00	\N
DTP00842	250311-PDD416	GOR	2	150.00	\N
DTP00843	250311-PDD417	TAZ	1	150.00	\N
DTP00844	250311-PDD417	LLA	3	100.00	\N
DTP00845	250311-PDD417	TAZ	2	200.00	\N
DTP00846	250311-PDD418	TAZ	1	150.00	\N
DTP00847	250311-PDD418	GOR	3	150.00	\N
DTP00848	250311-PDD418	CAM	2	200.00	\N
DTP00849	250311-PDD419	CAM	4	150.00	\N
DTP00850	250311-PDD420	LLA	3	100.00	\N
DTP00851	250311-PDD420	CAM	1	200.00	\N
DTP00852	250311-PDD421	TAZ	2	150.00	\N
DTP00853	250311-PDD421	GOR	2	150.00	\N
DTP00854	250311-PDD421	GOR	2	150.00	\N
DTP00855	250312-PDD422	LLA	2	150.00	\N
DTP00856	250312-PDD422	LLA	4	100.00	\N
DTP00857	250312-PDD422	TAZ	1	150.00	\N
DTP00858	250312-PDD423	LLA	3	100.00	\N
DTP00859	250312-PDD423	TER	1	170.00	\N
DTP00860	250312-PDD423	CAM	3	150.00	\N
DTP00861	250312-PDD424	TER	2	290.00	\N
DTP00862	250312-PDD425	TAZ	3	200.00	\N
DTP00863	250312-PDD425	TAZ	3	150.00	\N
DTP00864	250312-PDD425	LLA	3	120.00	\N
DTP00865	250312-PDD426	TAZ	3	150.00	\N
DTP00866	250312-PDD426	TER	4	290.00	\N
DTP00867	250312-PDD427	LLA	1	100.00	\N
DTP00868	250312-PDD427	TAZ	1	200.00	\N
DTP00869	250313-PDD428	TAZ	4	200.00	\N
DTP00870	250313-PDD429	LLA	3	120.00	\N
DTP00871	250313-PDD429	CAM	2	200.00	\N
DTP00872	250313-PDD429	TAZ	2	150.00	\N
DTP00873	250313-PDD430	GOR	1	150.00	\N
DTP00874	250313-PDD430	TAZ	4	150.00	\N
DTP00875	250313-PDD430	TAZ	4	200.00	\N
DTP00876	250313-PDD431	CAM	4	150.00	\N
DTP00877	250313-PDD431	LLA	2	150.00	\N
DTP00878	250313-PDD431	LLA	1	150.00	\N
DTP00879	250313-PDD432	TAZ	3	150.00	\N
DTP00880	250313-PDD432	GOR	2	150.00	\N
DTP00881	250313-PDD433	GOR	2	150.00	\N
DTP00882	250313-PDD433	GOR	3	150.00	\N
DTP00883	250314-PDD434	LLA	2	100.00	\N
DTP00884	250314-PDD434	GOR	1	150.00	\N
DTP00885	250314-PDD435	CAM	2	200.00	\N
DTP00886	250314-PDD436	GOR	1	150.00	\N
DTP00887	250314-PDD436	LLA	1	120.00	\N
DTP00888	250314-PDD437	CAM	2	150.00	\N
DTP00889	250314-PDD437	TAZ	2	200.00	\N
DTP00890	250314-PDD438	CAM	2	200.00	\N
DTP00891	250314-PDD439	CAM	1	150.00	\N
DTP00892	250314-PDD439	CAM	1	150.00	\N
DTP00893	250314-PDD439	LLA	3	150.00	\N
DTP00894	250315-PDD440	GOR	4	150.00	\N
DTP00895	250315-PDD441	TAZ	2	150.00	\N
DTP00896	250315-PDD441	CAM	3	150.00	\N
DTP00897	250315-PDD442	GOR	4	150.00	\N
DTP00898	250315-PDD442	LLA	2	120.00	\N
DTP00899	250315-PDD443	TER	2	170.00	\N
DTP00900	250315-PDD443	LLA	1	100.00	\N
DTP00901	250315-PDD443	GOR	3	150.00	\N
DTP00902	250315-PDD444	TAZ	1	200.00	\N
DTP00903	250315-PDD444	LLA	4	150.00	\N
DTP00904	250315-PDD444	LLA	2	120.00	\N
DTP00905	250315-PDD445	CAM	2	150.00	\N
DTP00906	250315-PDD445	CAM	2	200.00	\N
DTP00907	250316-PDD446	CAM	2	200.00	\N
DTP00908	250316-PDD447	TAZ	4	200.00	\N
DTP00909	250316-PDD448	LLA	3	100.00	\N
DTP00910	250316-PDD448	LLA	2	120.00	\N
DTP00911	250316-PDD449	GOR	2	150.00	\N
DTP00912	250316-PDD449	TAZ	1	200.00	\N
DTP00913	250316-PDD449	GOR	3	150.00	\N
DTP00914	250316-PDD450	GOR	1	150.00	\N
DTP00915	250316-PDD450	GOR	3	150.00	\N
DTP00916	250316-PDD450	TAZ	4	150.00	\N
DTP00917	250316-PDD451	GOR	4	150.00	\N
DTP00918	250316-PDD451	CAM	1	200.00	\N
DTP00919	250316-PDD451	TAZ	3	150.00	\N
DTP00920	250317-PDD452	TAZ	3	150.00	\N
DTP00921	250317-PDD452	LLA	1	120.00	\N
DTP00922	250317-PDD452	LLA	1	100.00	\N
DTP00923	250317-PDD453	GOR	3	150.00	\N
DTP00924	250317-PDD453	TAZ	3	150.00	\N
DTP00925	250317-PDD453	CAM	3	200.00	\N
DTP00926	250317-PDD454	GOR	3	150.00	\N
DTP00927	250317-PDD454	GOR	2	150.00	\N
DTP00928	250317-PDD455	GOR	2	150.00	\N
DTP00929	250317-PDD455	GOR	3	150.00	\N
DTP00930	250317-PDD456	GOR	4	150.00	\N
DTP00931	250317-PDD457	TAZ	3	200.00	\N
DTP00932	250317-PDD457	TAZ	3	150.00	\N
DTP00933	250318-PDD458	CAM	1	150.00	\N
DTP00934	250318-PDD458	CAM	4	200.00	\N
DTP00935	250318-PDD459	TAZ	3	200.00	\N
DTP00936	250318-PDD459	LLA	3	100.00	\N
DTP00937	250318-PDD459	TAZ	3	150.00	\N
DTP00938	250318-PDD460	CAM	3	200.00	\N
DTP00939	250318-PDD460	GOR	1	150.00	\N
DTP00940	250318-PDD460	GOR	4	150.00	\N
DTP00941	250318-PDD461	GOR	3	150.00	\N
DTP00942	250318-PDD461	GOR	2	150.00	\N
DTP00943	250318-PDD462	GOR	3	150.00	\N
DTP00944	250318-PDD462	CAM	1	150.00	\N
DTP00945	250318-PDD463	GOR	2	150.00	\N
DTP00946	250318-PDD463	TAZ	1	200.00	\N
DTP00947	250318-PDD463	CAM	4	150.00	\N
DTP00948	250319-PDD464	GOR	4	150.00	\N
DTP00949	250319-PDD464	GOR	3	150.00	\N
DTP00950	250319-PDD464	LLA	2	150.00	\N
DTP00951	250319-PDD465	GOR	1	150.00	\N
DTP00952	250319-PDD466	TAZ	4	200.00	\N
DTP00953	250319-PDD466	TAZ	2	200.00	\N
DTP00954	250319-PDD466	GOR	1	150.00	\N
DTP00955	250319-PDD467	TAZ	1	150.00	\N
DTP00956	250319-PDD467	GOR	1	150.00	\N
DTP00957	250319-PDD468	GOR	3	150.00	\N
DTP00958	250319-PDD468	TER	2	290.00	\N
DTP00959	250319-PDD468	LLA	2	120.00	\N
DTP00960	250319-PDD469	GOR	3	150.00	\N
DTP00961	250319-PDD469	LLA	3	100.00	\N
DTP00962	250320-PDD470	CAM	4	200.00	\N
DTP00963	250320-PDD470	LLA	3	100.00	\N
DTP00964	250320-PDD470	GOR	1	150.00	\N
DTP00965	250320-PDD471	CAM	4	200.00	\N
DTP00966	250320-PDD472	GOR	3	150.00	\N
DTP00967	250320-PDD472	TER	2	170.00	\N
DTP00968	250320-PDD473	TAZ	4	200.00	\N
DTP00969	250320-PDD473	GOR	3	150.00	\N
DTP00970	250320-PDD473	GOR	3	150.00	\N
DTP00971	250320-PDD474	GOR	1	150.00	\N
DTP00972	250320-PDD475	GOR	2	150.00	\N
DTP00973	250320-PDD475	GOR	3	150.00	\N
DTP00974	250320-PDD475	TAZ	4	200.00	\N
DTP00975	250321-PDD476	TAZ	2	200.00	\N
DTP00976	250321-PDD477	TAZ	4	200.00	\N
DTP00977	250321-PDD477	TAZ	3	200.00	\N
DTP00978	250321-PDD478	LLA	4	100.00	\N
DTP00979	250321-PDD478	CAM	4	200.00	\N
DTP00980	250321-PDD479	GOR	2	150.00	\N
DTP00981	250321-PDD480	TAZ	3	150.00	\N
DTP00982	250321-PDD480	GOR	2	150.00	\N
DTP00983	250321-PDD481	TAZ	1	150.00	\N
DTP00984	250321-PDD481	TAZ	2	150.00	\N
DTP00985	250322-PDD482	TER	4	170.00	\N
DTP00986	250322-PDD482	TAZ	4	200.00	\N
DTP00987	250322-PDD483	LLA	4	150.00	\N
DTP00988	250322-PDD483	TER	2	290.00	\N
DTP00989	250322-PDD484	TAZ	4	150.00	\N
DTP00990	250322-PDD484	CAM	3	150.00	\N
DTP00991	250322-PDD484	LLA	1	120.00	\N
DTP00992	250322-PDD485	TAZ	3	200.00	\N
DTP00993	250322-PDD485	TAZ	3	150.00	\N
DTP00994	250322-PDD486	CAM	2	200.00	\N
DTP00995	250322-PDD486	GOR	4	150.00	\N
DTP00996	250322-PDD487	GOR	1	150.00	\N
DTP00997	250323-PDD488	LLA	3	100.00	\N
DTP00998	250323-PDD488	GOR	1	150.00	\N
DTP00999	250323-PDD488	GOR	1	150.00	\N
DTP01000	250323-PDD489	TAZ	3	200.00	\N
DTP01001	250323-PDD490	TAZ	3	200.00	\N
DTP01002	250323-PDD490	TAZ	1	200.00	\N
DTP01003	250323-PDD491	GOR	2	150.00	\N
DTP01004	250323-PDD491	TER	4	290.00	\N
DTP01005	250323-PDD492	TAZ	1	200.00	\N
DTP01006	250323-PDD492	TER	3	290.00	\N
DTP01007	250323-PDD492	GOR	3	150.00	\N
DTP01008	250323-PDD493	LLA	1	100.00	\N
DTP01009	250323-PDD493	TAZ	2	200.00	\N
DTP01010	250324-PDD494	TAZ	1	150.00	\N
DTP01011	250324-PDD494	GOR	4	150.00	\N
DTP01012	250324-PDD495	LLA	2	100.00	\N
DTP01013	250324-PDD495	GOR	2	150.00	\N
DTP01014	250324-PDD495	TAZ	4	150.00	\N
DTP01015	250324-PDD496	TAZ	1	150.00	\N
DTP01016	250324-PDD497	TAZ	1	150.00	\N
DTP01017	250324-PDD498	TER	2	170.00	\N
DTP01018	250324-PDD499	GOR	2	150.00	\N
DTP01019	250325-PDD500	LLA	2	150.00	\N
DTP01020	250325-PDD501	CAM	1	150.00	\N
DTP01021	250325-PDD501	TER	2	290.00	\N
DTP01022	250325-PDD501	LLA	3	150.00	\N
DTP01023	250325-PDD502	LLA	1	100.00	\N
DTP01024	250325-PDD503	TAZ	3	200.00	\N
DTP01025	250325-PDD503	TAZ	4	200.00	\N
DTP01026	250325-PDD504	LLA	3	100.00	\N
DTP01027	250325-PDD504	GOR	1	150.00	\N
DTP01028	250325-PDD505	TAZ	4	150.00	\N
DTP01029	250325-PDD505	TAZ	1	150.00	\N
DTP01030	250326-PDD506	GOR	3	150.00	\N
DTP01031	250326-PDD506	TAZ	1	150.00	\N
DTP01032	250326-PDD506	CAM	2	200.00	\N
DTP01033	250326-PDD507	GOR	2	150.00	\N
DTP01034	250326-PDD507	GOR	1	150.00	\N
DTP01035	250326-PDD508	GOR	1	150.00	\N
DTP01036	250326-PDD509	LLA	2	120.00	\N
DTP01037	250326-PDD509	LLA	3	100.00	\N
DTP01038	250326-PDD510	CAM	4	200.00	\N
DTP01039	250326-PDD511	TAZ	1	150.00	\N
DTP01040	250326-PDD511	GOR	2	150.00	\N
DTP01041	250327-PDD512	LLA	1	120.00	\N
DTP01042	250327-PDD512	GOR	3	150.00	\N
DTP01043	250327-PDD512	GOR	3	150.00	\N
DTP01044	250327-PDD513	TAZ	4	200.00	\N
DTP01045	250327-PDD513	GOR	2	150.00	\N
DTP01046	250327-PDD514	LLA	2	120.00	\N
DTP01047	250327-PDD514	TER	4	290.00	\N
DTP01048	250327-PDD515	GOR	4	150.00	\N
DTP01049	250327-PDD515	TAZ	1	150.00	\N
DTP01050	250327-PDD516	CAM	1	200.00	\N
DTP01051	250327-PDD517	CAM	3	200.00	\N
DTP01052	250327-PDD517	GOR	4	150.00	\N
DTP01053	250328-PDD518	TAZ	4	200.00	\N
DTP01054	250328-PDD519	CAM	2	150.00	\N
DTP01055	250328-PDD519	GOR	3	150.00	\N
DTP01056	250328-PDD519	TAZ	4	150.00	\N
DTP01057	250328-PDD520	CAM	2	150.00	\N
DTP01058	250328-PDD520	GOR	3	150.00	\N
DTP01059	250328-PDD520	TAZ	2	200.00	\N
DTP01060	250328-PDD521	GOR	1	150.00	\N
DTP01061	250328-PDD522	TER	4	290.00	\N
DTP01062	250328-PDD523	TAZ	2	200.00	\N
DTP01063	250328-PDD523	GOR	3	150.00	\N
DTP01064	250329-PDD524	GOR	1	150.00	\N
DTP01065	250329-PDD525	LLA	4	150.00	\N
DTP01066	250329-PDD525	CAM	3	150.00	\N
DTP01067	250329-PDD526	TAZ	3	150.00	\N
DTP01068	250329-PDD527	LLA	2	100.00	\N
DTP01069	250329-PDD527	CAM	3	200.00	\N
DTP01070	250329-PDD527	GOR	4	150.00	\N
DTP01071	250329-PDD528	CAM	4	200.00	\N
DTP01072	250329-PDD528	GOR	2	150.00	\N
DTP01073	250329-PDD529	GOR	1	150.00	\N
DTP01074	250330-PDD530	LLA	1	120.00	\N
DTP01075	250330-PDD530	GOR	4	150.00	\N
DTP01076	250330-PDD531	GOR	4	150.00	\N
DTP01077	250330-PDD531	GOR	2	150.00	\N
DTP01078	250330-PDD531	CAM	3	150.00	\N
DTP01079	250330-PDD532	TER	2	170.00	\N
DTP01080	250330-PDD533	TAZ	1	200.00	\N
DTP01081	250330-PDD533	TER	2	170.00	\N
DTP01082	250330-PDD533	CAM	2	150.00	\N
DTP01083	250330-PDD534	GOR	3	150.00	\N
DTP01084	250330-PDD534	LLA	1	120.00	\N
DTP01085	250330-PDD534	LLA	3	120.00	\N
DTP01086	250330-PDD535	CAM	1	200.00	\N
DTP01087	250330-PDD535	GOR	2	150.00	\N
DTP01088	250330-PDD535	TAZ	3	150.00	\N
DTP01089	250331-PDD536	TAZ	4	200.00	\N
DTP01090	250331-PDD537	CAM	4	200.00	\N
DTP01091	250331-PDD538	LLA	4	150.00	\N
DTP01092	250331-PDD539	LLA	3	150.00	\N
DTP01093	250331-PDD539	LLA	2	120.00	\N
DTP01094	250331-PDD540	TAZ	2	200.00	\N
DTP01095	250331-PDD540	TAZ	3	150.00	\N
DTP01096	250331-PDD541	CAM	3	200.00	\N
DTP01097	250331-PDD541	TAZ	2	200.00	\N
DTP01098	250401-PDD542	GOR	2	150.00	\N
DTP01099	250401-PDD543	TAZ	4	200.00	\N
DTP01100	250401-PDD544	TAZ	4	150.00	\N
DTP01101	250401-PDD545	TAZ	3	200.00	\N
DTP01102	250401-PDD545	GOR	2	150.00	\N
DTP01103	250401-PDD546	TER	3	290.00	\N
DTP01104	250401-PDD546	CAM	4	150.00	\N
DTP01105	250401-PDD546	TAZ	2	200.00	\N
DTP01106	250401-PDD547	CAM	1	150.00	\N
DTP01107	250401-PDD547	GOR	1	150.00	\N
DTP01108	250402-PDD548	CAM	2	200.00	\N
DTP01109	250402-PDD548	GOR	1	150.00	\N
DTP01110	250402-PDD549	LLA	4	150.00	\N
DTP01111	250402-PDD550	LLA	2	150.00	\N
DTP01112	250402-PDD550	GOR	2	150.00	\N
DTP01113	250402-PDD551	GOR	4	150.00	\N
DTP01114	250402-PDD551	CAM	2	150.00	\N
DTP01115	250402-PDD551	TAZ	2	150.00	\N
DTP01116	250402-PDD552	GOR	3	150.00	\N
DTP01117	250402-PDD552	LLA	2	150.00	\N
DTP01118	250402-PDD552	GOR	3	150.00	\N
DTP01119	250402-PDD553	LLA	3	100.00	\N
DTP01120	250403-PDD554	GOR	2	150.00	\N
DTP01121	250403-PDD554	CAM	1	150.00	\N
DTP01122	250403-PDD555	CAM	4	150.00	\N
DTP01123	250403-PDD555	CAM	2	200.00	\N
DTP01124	250403-PDD555	TAZ	4	150.00	\N
DTP01125	250403-PDD556	CAM	1	150.00	\N
DTP01126	250403-PDD556	GOR	1	150.00	\N
DTP01127	250403-PDD556	TAZ	4	150.00	\N
DTP01128	250403-PDD557	GOR	4	150.00	\N
DTP01129	250403-PDD558	TAZ	4	150.00	\N
DTP01130	250403-PDD558	CAM	4	200.00	\N
DTP01131	250403-PDD558	TAZ	1	150.00	\N
DTP01132	250403-PDD559	CAM	3	200.00	\N
DTP01133	250404-PDD560	TER	3	290.00	\N
DTP01134	250404-PDD561	LLA	2	120.00	\N
DTP01135	250404-PDD561	LLA	4	150.00	\N
DTP01136	250404-PDD561	LLA	2	150.00	\N
DTP01137	250404-PDD562	CAM	4	200.00	\N
DTP01138	250404-PDD562	GOR	4	150.00	\N
DTP01139	250404-PDD562	GOR	4	150.00	\N
DTP01140	250404-PDD563	TAZ	3	150.00	\N
DTP01141	250404-PDD564	GOR	1	150.00	\N
DTP01142	250404-PDD564	LLA	3	100.00	\N
DTP01143	250404-PDD564	LLA	2	100.00	\N
DTP01144	250404-PDD565	GOR	4	150.00	\N
DTP01145	250404-PDD565	CAM	2	150.00	\N
DTP01146	250405-PDD566	TAZ	3	200.00	\N
DTP01147	250405-PDD567	LLA	4	150.00	\N
DTP01148	250405-PDD567	CAM	3	200.00	\N
DTP01149	250405-PDD568	TER	1	170.00	\N
DTP01150	250405-PDD568	GOR	4	150.00	\N
DTP01151	250405-PDD568	TAZ	4	150.00	\N
DTP01152	250405-PDD569	CAM	1	150.00	\N
DTP01153	250405-PDD569	LLA	1	150.00	\N
DTP01154	250405-PDD570	LLA	1	100.00	\N
DTP01155	250405-PDD571	TER	1	290.00	\N
DTP01156	250406-PDD572	GOR	4	150.00	\N
DTP01157	250406-PDD572	GOR	2	150.00	\N
DTP01158	250406-PDD573	CAM	2	200.00	\N
DTP01159	250406-PDD573	LLA	4	150.00	\N
DTP01160	250406-PDD573	GOR	1	150.00	\N
DTP01161	250406-PDD574	GOR	1	150.00	\N
DTP01162	250406-PDD574	TAZ	4	200.00	\N
DTP01163	250406-PDD575	GOR	4	150.00	\N
DTP01164	250406-PDD576	LLA	4	100.00	\N
DTP01165	250406-PDD576	CAM	2	150.00	\N
DTP01166	250406-PDD577	TAZ	2	150.00	\N
DTP01167	250406-PDD577	CAM	1	150.00	\N
DTP01168	250407-PDD578	CAM	3	150.00	\N
DTP01169	250407-PDD578	GOR	3	150.00	\N
DTP01170	250407-PDD578	CAM	2	150.00	\N
DTP01171	250407-PDD579	TAZ	2	200.00	\N
DTP01172	250407-PDD580	GOR	3	150.00	\N
DTP01173	250407-PDD581	LLA	1	120.00	\N
DTP01174	250407-PDD581	TAZ	2	200.00	\N
DTP01175	250407-PDD582	TER	4	170.00	\N
DTP01176	250407-PDD583	CAM	4	200.00	\N
DTP01177	250407-PDD583	GOR	2	150.00	\N
DTP01178	250407-PDD583	LLA	3	150.00	\N
DTP01179	250408-PDD584	TAZ	4	200.00	\N
DTP01180	250408-PDD585	TER	3	170.00	\N
DTP01181	250408-PDD585	TAZ	2	200.00	\N
DTP01182	250408-PDD586	TAZ	3	150.00	\N
DTP01183	250408-PDD586	CAM	2	200.00	\N
DTP01184	250408-PDD587	GOR	3	150.00	\N
DTP01185	250408-PDD588	TAZ	3	150.00	\N
DTP01186	250408-PDD589	TAZ	3	200.00	\N
\.


--
-- Data for Name: especificacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.especificacion (especificacion_id, nombre) FROM stdin;
1	Talla
2	Color
3	Material
4	Estilo
5	Forma
6	Envase
\.


--
-- Data for Name: estados; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.estados (estado_id, nombre) FROM stdin;
1	Creado
2	En Produccion
3	En Espera
4	Listo
5	Entregado
6	Rechazado
\.


--
-- Data for Name: metodo_envio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.metodo_envio (metodo_id, nombre) FROM stdin;
4	C807 Xpress
3	Express 504
2	CAEX
1	Recoger en Tienda
\.


--
-- Data for Name: pedido_especificacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pedido_especificacion (pedido_especificacion_id, detalle_pedido_id, especificacion_id, valor) FROM stdin;
CAM-1001	DTP00001	1	XL
CAM-2001	DTP00001	2	Verde
GOR-2002	DTP00002	2	Negro
GOR-2003	DTP00003	2	Rosado
GOR-2004	DTP00004	2	Azul
GOR-2005	DTP00005	2	Azul
GOR-2006	DTP00006	2	Verde
LLA-3001	DTP00007	3	PVC
LLA-5001	DTP00007	5	Rectangular
LLA-3002	DTP00008	3	PVC
LLA-5002	DTP00008	5	Circular
GOR-2007	DTP00009	2	Gris
LLA-3003	DTP00010	3	PVC
LLA-5003	DTP00010	5	Corazon
GOR-2008	DTP00011	2	Negro
LLA-3004	DTP00012	3	Madera
LLA-5004	DTP00012	5	Rectangular
GOR-2009	DTP00013	2	Rosado
GOR-2010	DTP00014	2	Verde
TAZ-4001	DTP00015	4	Magica
LLA-3005	DTP00016	3	Madera
LLA-5005	DTP00016	5	Corazon
TAZ-4002	DTP00017	4	Magica
TAZ-4003	DTP00018	4	Magica
CAM-1002	DTP00019	1	6
CAM-2011	DTP00019	2	Negro
TAZ-4004	DTP00020	4	Magica
CAM-1003	DTP00021	1	12
CAM-2012	DTP00021	2	Azul
TER-2013	DTP00022	2	Morado
TER-6001	DTP00022	6	Aluminio
LLA-3006	DTP00023	3	Metal
LLA-5006	DTP00023	5	Corazon
GOR-2014	DTP00024	2	Gris
GOR-2015	DTP00025	2	Morado
GOR-2016	DTP00026	2	Azul
GOR-2017	DTP00027	2	Azul
TAZ-4005	DTP00028	4	Magica
TER-2018	DTP00029	2	Amarillo
TER-6002	DTP00029	6	Aluminio
GOR-2019	DTP00030	2	Rosado
LLA-3007	DTP00031	3	Madera
LLA-5007	DTP00031	5	Corazon
GOR-2020	DTP00032	2	Morado
TAZ-4006	DTP00033	4	Magica
TAZ-4007	DTP00034	4	Normal
GOR-2021	DTP00035	2	Gris
TAZ-4008	DTP00036	4	Magica
GOR-2022	DTP00037	2	Morado
LLA-3008	DTP00038	3	PVC
LLA-5008	DTP00038	5	Circular
GOR-2023	DTP00039	2	Rosado
GOR-2024	DTP00040	2	Blanco
TAZ-4009	DTP00041	4	Normal
CAM-1004	DTP00042	1	6
CAM-2025	DTP00042	2	Amarillo
TAZ-4010	DTP00043	4	Magica
GOR-2026	DTP00044	2	Gris
GOR-2027	DTP00045	2	Amarillo
CAM-1005	DTP00046	1	12
CAM-2028	DTP00046	2	Rosado
GOR-2029	DTP00047	2	Gris
TAZ-4011	DTP00048	4	Magica
LLA-3009	DTP00049	3	Madera
LLA-5009	DTP00049	5	Rectangular
CAM-1006	DTP00050	1	8
CAM-2030	DTP00050	2	Verde
LLA-3010	DTP00051	3	PVC
LLA-5010	DTP00051	5	Circular
LLA-3011	DTP00052	3	PVC
LLA-5011	DTP00052	5	Rectangular
GOR-2031	DTP00053	2	Morado
TAZ-4012	DTP00054	4	Magica
TER-2032	DTP00055	2	Rojo
TER-6003	DTP00055	6	Plastico
CAM-1007	DTP00056	1	L
CAM-2033	DTP00056	2	Rosado
TAZ-4013	DTP00057	4	Magica
CAM-1008	DTP00058	1	L
CAM-2034	DTP00058	2	Verde
CAM-1009	DTP00059	1	6
CAM-2035	DTP00059	2	Amarillo
CAM-1010	DTP00060	1	6
CAM-2036	DTP00060	2	Morado
CAM-1011	DTP00061	1	XL
CAM-2037	DTP00061	2	Amarillo
LLA-3012	DTP00062	3	Metal
LLA-5012	DTP00062	5	Corazon
LLA-3013	DTP00063	3	Metal
LLA-5013	DTP00063	5	Corazon
GOR-2038	DTP00064	2	Gris
GOR-2039	DTP00065	2	Gris
GOR-2040	DTP00066	2	Blanco
CAM-1012	DTP00067	1	S
CAM-2041	DTP00067	2	Morado
GOR-2042	DTP00068	2	Gris
CAM-1013	DTP00069	1	4
CAM-2043	DTP00069	2	Blanco
GOR-2044	DTP00070	2	Negro
TAZ-4014	DTP00071	4	Normal
CAM-1014	DTP00072	1	14
CAM-2045	DTP00072	2	Amarillo
CAM-1015	DTP00073	1	L
CAM-2046	DTP00073	2	Verde
CAM-1016	DTP00074	1	12
CAM-2047	DTP00074	2	Gris
LLA-3014	DTP00075	3	Madera
LLA-5014	DTP00075	5	Rectangular
CAM-1017	DTP00076	1	L
CAM-2048	DTP00076	2	Gris
TAZ-4015	DTP00077	4	Normal
LLA-3015	DTP00078	3	PVC
LLA-5015	DTP00078	5	Circular
GOR-2049	DTP00079	2	Rosado
GOR-2050	DTP00080	2	Negro
TAZ-4016	DTP00081	4	Normal
CAM-1018	DTP00082	1	6
CAM-2051	DTP00082	2	Amarillo
TAZ-4017	DTP00083	4	Magica
LLA-3016	DTP00084	3	Metal
LLA-5016	DTP00084	5	Circular
CAM-1019	DTP00085	1	6
CAM-2052	DTP00085	2	Rojo
LLA-3017	DTP00086	3	Madera
LLA-5017	DTP00086	5	Corazon
TAZ-4018	DTP00087	4	Magica
GOR-2053	DTP00088	2	Negro
TAZ-4019	DTP00089	4	Normal
GOR-2054	DTP00090	2	Morado
TAZ-4020	DTP00091	4	Magica
TAZ-4021	DTP00092	4	Magica
TAZ-4022	DTP00093	4	Normal
CAM-1020	DTP00094	1	12
CAM-2055	DTP00094	2	Rosado
TAZ-4023	DTP00095	4	Normal
TAZ-4024	DTP00096	4	Normal
CAM-1021	DTP00097	1	L
CAM-2056	DTP00097	2	Amarillo
TAZ-4025	DTP00098	4	Magica
TER-2057	DTP00099	2	Gris
TER-6004	DTP00099	6	Plastico
CAM-1022	DTP00100	1	12
CAM-2058	DTP00100	2	Azul
TAZ-4026	DTP00101	4	Magica
GOR-2059	DTP00102	2	Blanco
CAM-1023	DTP00103	1	XL
CAM-2060	DTP00103	2	Morado
GOR-2061	DTP00104	2	Gris
LLA-3018	DTP00105	3	Madera
LLA-5018	DTP00105	5	Corazon
CAM-1024	DTP00106	1	S
CAM-2062	DTP00106	2	Rosado
GOR-2063	DTP00107	2	Negro
GOR-2064	DTP00108	2	Rojo
LLA-3019	DTP00109	3	PVC
LLA-5019	DTP00109	5	Rectangular
CAM-1025	DTP00110	1	12
CAM-2065	DTP00110	2	Rojo
GOR-2066	DTP00111	2	Amarillo
CAM-1026	DTP00112	1	XL
CAM-2067	DTP00112	2	Gris
LLA-3020	DTP00113	3	PVC
LLA-5020	DTP00113	5	Circular
GOR-2068	DTP00114	2	Morado
GOR-2069	DTP00115	2	Verde
TAZ-4027	DTP00116	4	Normal
GOR-2070	DTP00117	2	Rojo
TAZ-4028	DTP00118	4	Normal
GOR-2071	DTP00119	2	Rojo
TER-2072	DTP00120	2	Azul
TER-6005	DTP00120	6	Aluminio
TAZ-4029	DTP00121	4	Magica
CAM-1027	DTP00122	1	XL
CAM-2073	DTP00122	2	Morado
LLA-3021	DTP00123	3	PVC
LLA-5021	DTP00123	5	Corazon
CAM-1028	DTP00124	1	S
CAM-2074	DTP00124	2	Verde
LLA-3022	DTP00125	3	Madera
LLA-5022	DTP00125	5	Circular
GOR-2075	DTP00126	2	Blanco
TAZ-4030	DTP00127	4	Magica
GOR-2076	DTP00128	2	Negro
GOR-2077	DTP00129	2	Blanco
CAM-1029	DTP00130	1	6
CAM-2078	DTP00130	2	Gris
GOR-2079	DTP00131	2	Gris
TAZ-4031	DTP00132	4	Magica
GOR-2080	DTP00133	2	Rojo
TAZ-4032	DTP00134	4	Normal
CAM-1030	DTP00135	1	12
CAM-2081	DTP00135	2	Azul
LLA-3023	DTP00136	3	PVC
LLA-5023	DTP00136	5	Circular
CAM-1031	DTP00137	1	XL
CAM-2082	DTP00137	2	Blanco
TAZ-4033	DTP00138	4	Magica
TAZ-4034	DTP00139	4	Magica
GOR-2083	DTP00140	2	Rojo
LLA-3024	DTP00141	3	Metal
LLA-5024	DTP00141	5	Circular
GOR-2084	DTP00142	2	Azul
CAM-1032	DTP00143	1	6
CAM-2085	DTP00143	2	Verde
TAZ-4035	DTP00144	4	Magica
TAZ-4036	DTP00145	4	Magica
TAZ-4037	DTP00146	4	Normal
TAZ-4038	DTP00147	4	Normal
CAM-1033	DTP00148	1	6
CAM-2086	DTP00148	2	Amarillo
GOR-2087	DTP00149	2	Rosado
GOR-2088	DTP00150	2	Negro
TAZ-4039	DTP00151	4	Normal
TAZ-4040	DTP00152	4	Magica
CAM-1034	DTP00153	1	6
CAM-2089	DTP00153	2	Negro
GOR-2090	DTP00154	2	Amarillo
CAM-1035	DTP00155	1	4
CAM-2091	DTP00155	2	Gris
LLA-3025	DTP00156	3	Metal
LLA-5025	DTP00156	5	Rectangular
CAM-1036	DTP00157	1	4
CAM-2092	DTP00157	2	Morado
GOR-2093	DTP00158	2	Blanco
GOR-2094	DTP00159	2	Azul
LLA-3026	DTP00160	3	Madera
LLA-5026	DTP00160	5	Corazon
CAM-1037	DTP00161	1	12
CAM-2095	DTP00161	2	Azul
LLA-3027	DTP00162	3	PVC
LLA-5027	DTP00162	5	Circular
TAZ-4041	DTP00163	4	Magica
LLA-3028	DTP00164	3	PVC
LLA-5028	DTP00164	5	Corazon
TAZ-4042	DTP00165	4	Magica
TER-2096	DTP00166	2	Azul
TER-6006	DTP00166	6	Aluminio
TAZ-4043	DTP00167	4	Magica
GOR-2097	DTP00168	2	Verde
LLA-3029	DTP00169	3	Metal
LLA-5029	DTP00169	5	Rectangular
TER-2098	DTP00170	2	Gris
TER-6007	DTP00170	6	Aluminio
TAZ-4044	DTP00171	4	Magica
TAZ-4045	DTP00172	4	Magica
TAZ-4046	DTP00173	4	Magica
GOR-2099	DTP00174	2	Amarillo
CAM-1038	DTP00175	1	14
CAM-2100	DTP00175	2	Verde
TAZ-4047	DTP00176	4	Normal
TAZ-4048	DTP00177	4	Magica
LLA-3030	DTP00178	3	PVC
LLA-5030	DTP00178	5	Corazon
GOR-2101	DTP00179	2	Negro
TER-2102	DTP00180	2	Morado
TER-6008	DTP00180	6	Aluminio
GOR-2103	DTP00181	2	Verde
TAZ-4049	DTP00182	4	Normal
TAZ-4050	DTP00183	4	Magica
GOR-2104	DTP00184	2	Gris
GOR-2105	DTP00185	2	Blanco
CAM-1039	DTP00186	1	4
CAM-2106	DTP00186	2	Morado
TAZ-4051	DTP00187	4	Normal
GOR-2107	DTP00188	2	Rojo
CAM-1040	DTP00189	1	14
CAM-2108	DTP00189	2	Blanco
TAZ-4052	DTP00190	4	Normal
TAZ-4053	DTP00191	4	Normal
GOR-2109	DTP00192	2	Azul
GOR-2110	DTP00193	2	Negro
TAZ-4054	DTP00194	4	Magica
TAZ-4055	DTP00195	4	Normal
CAM-1041	DTP00196	1	8
CAM-2111	DTP00196	2	Gris
LLA-3031	DTP00197	3	PVC
LLA-5031	DTP00197	5	Rectangular
TER-2112	DTP00198	2	Azul
TER-6009	DTP00198	6	Plastico
CAM-1042	DTP00199	1	XXL
CAM-2113	DTP00199	2	Rosado
TAZ-4056	DTP00200	4	Normal
TAZ-4057	DTP00201	4	Magica
CAM-1043	DTP00202	1	XXL
CAM-2114	DTP00202	2	Amarillo
CAM-1044	DTP00203	1	6
CAM-2115	DTP00203	2	Azul
GOR-2116	DTP00204	2	Rojo
CAM-1045	DTP00205	1	4
CAM-2117	DTP00205	2	Rosado
GOR-2118	DTP00206	2	Gris
GOR-2119	DTP00207	2	Amarillo
LLA-3032	DTP00208	3	PVC
LLA-5032	DTP00208	5	Rectangular
GOR-2120	DTP00209	2	Negro
GOR-2121	DTP00210	2	Negro
TAZ-4058	DTP00211	4	Magica
GOR-2122	DTP00212	2	Azul
GOR-2123	DTP00213	2	Gris
TAZ-4059	DTP00214	4	Normal
GOR-2124	DTP00215	2	Rojo
TAZ-4060	DTP00216	4	Normal
TAZ-4061	DTP00217	4	Magica
LLA-3033	DTP00218	3	Metal
LLA-5033	DTP00218	5	Corazon
TAZ-4062	DTP00219	4	Magica
GOR-2125	DTP00220	2	Rosado
CAM-1046	DTP00221	1	M
CAM-2126	DTP00221	2	Amarillo
TAZ-4063	DTP00222	4	Normal
CAM-1047	DTP00223	1	XL
CAM-2127	DTP00223	2	Verde
TAZ-4064	DTP00224	4	Magica
CAM-1048	DTP00225	1	L
CAM-2128	DTP00225	2	Morado
CAM-1049	DTP00226	1	12
CAM-2129	DTP00226	2	Negro
TAZ-4065	DTP00227	4	Magica
CAM-1050	DTP00228	1	S
CAM-2130	DTP00228	2	Morado
TAZ-4066	DTP00229	4	Normal
GOR-2131	DTP00230	2	Rojo
TAZ-4067	DTP00231	4	Magica
GOR-2132	DTP00232	2	Verde
CAM-1051	DTP00233	1	S
CAM-2133	DTP00233	2	Azul
TER-2134	DTP00234	2	Rosado
TER-6010	DTP00234	6	Plastico
TER-2135	DTP00235	2	Rosado
TER-6011	DTP00235	6	Aluminio
GOR-2136	DTP00236	2	Rosado
CAM-1052	DTP00237	1	12
CAM-2137	DTP00237	2	Rojo
GOR-2138	DTP00238	2	Gris
TAZ-4068	DTP00239	4	Magica
CAM-1053	DTP00240	1	XXL
CAM-2139	DTP00240	2	Azul
LLA-3034	DTP00241	3	Madera
LLA-5034	DTP00241	5	Corazon
TAZ-4069	DTP00242	4	Magica
LLA-3035	DTP00243	3	Metal
LLA-5035	DTP00243	5	Circular
GOR-2140	DTP00244	2	Azul
LLA-3036	DTP00245	3	PVC
LLA-5036	DTP00245	5	Corazon
TAZ-4070	DTP00246	4	Normal
TAZ-4071	DTP00247	4	Magica
LLA-3037	DTP00248	3	PVC
LLA-5037	DTP00248	5	Corazon
TER-2141	DTP00249	2	Azul
TER-6012	DTP00249	6	Aluminio
CAM-1054	DTP00250	1	8
CAM-2142	DTP00250	2	Morado
TAZ-4072	DTP00251	4	Magica
TER-2143	DTP00252	2	Blanco
TER-6013	DTP00252	6	Aluminio
GOR-2144	DTP00253	2	Negro
TAZ-4073	DTP00254	4	Normal
TER-2145	DTP00255	2	Rojo
TER-6014	DTP00255	6	Aluminio
TAZ-4074	DTP00256	4	Magica
TAZ-4075	DTP00257	4	Magica
CAM-1055	DTP00258	1	6
CAM-2146	DTP00258	2	Amarillo
LLA-3038	DTP00259	3	PVC
LLA-5038	DTP00259	5	Rectangular
GOR-2147	DTP00260	2	Azul
CAM-1056	DTP00261	1	8
CAM-2148	DTP00261	2	Amarillo
CAM-1057	DTP00262	1	14
CAM-2149	DTP00262	2	Amarillo
GOR-2150	DTP00263	2	Verde
CAM-1058	DTP00264	1	6
CAM-2151	DTP00264	2	Gris
GOR-2152	DTP00265	2	Morado
GOR-2153	DTP00266	2	Azul
TAZ-4076	DTP00267	4	Magica
LLA-3039	DTP00268	3	PVC
LLA-5039	DTP00268	5	Circular
TAZ-4077	DTP00269	4	Magica
CAM-1059	DTP00270	1	4
CAM-2154	DTP00270	2	Amarillo
TAZ-4078	DTP00271	4	Normal
CAM-1060	DTP00272	1	XXL
CAM-2155	DTP00272	2	Verde
LLA-3040	DTP00273	3	Madera
LLA-5040	DTP00273	5	Corazon
GOR-2156	DTP00274	2	Negro
LLA-3041	DTP00275	3	Metal
LLA-5041	DTP00275	5	Rectangular
CAM-1061	DTP00276	1	14
CAM-2157	DTP00276	2	Verde
CAM-1062	DTP00277	1	XL
CAM-2158	DTP00277	2	Rosado
GOR-2159	DTP00278	2	Negro
TAZ-4079	DTP00279	4	Magica
LLA-3042	DTP00280	3	Madera
LLA-5042	DTP00280	5	Rectangular
GOR-2160	DTP00281	2	Rosado
GOR-2161	DTP00282	2	Amarillo
TAZ-4080	DTP00283	4	Magica
TAZ-4081	DTP00284	4	Normal
GOR-2162	DTP00285	2	Negro
GOR-2163	DTP00286	2	Blanco
CAM-1063	DTP00287	1	S
CAM-2164	DTP00287	2	Azul
TER-2165	DTP00288	2	Azul
TER-6015	DTP00288	6	Plastico
GOR-2166	DTP00289	2	Amarillo
CAM-1064	DTP00290	1	14
CAM-2167	DTP00290	2	Negro
CAM-1065	DTP00291	1	S
CAM-2168	DTP00291	2	Negro
GOR-2169	DTP00292	2	Morado
TAZ-4082	DTP00293	4	Normal
LLA-3043	DTP00294	3	PVC
LLA-5043	DTP00294	5	Rectangular
TAZ-4083	DTP00295	4	Magica
GOR-2170	DTP00296	2	Amarillo
GOR-2171	DTP00297	2	Blanco
LLA-3044	DTP00298	3	Madera
LLA-5044	DTP00298	5	Corazon
TAZ-4084	DTP00299	4	Magica
CAM-1066	DTP00300	1	6
CAM-2172	DTP00300	2	Rojo
GOR-2173	DTP00301	2	Rosado
GOR-2174	DTP00302	2	Verde
CAM-1067	DTP00303	1	6
CAM-2175	DTP00303	2	Rosado
LLA-3045	DTP00304	3	Madera
LLA-5045	DTP00304	5	Circular
GOR-2176	DTP00305	2	Blanco
GOR-2177	DTP00306	2	Negro
GOR-2178	DTP00307	2	Rojo
GOR-2179	DTP00308	2	Azul
TAZ-4085	DTP00309	4	Magica
CAM-1068	DTP00310	1	XL
CAM-2180	DTP00310	2	Azul
GOR-2181	DTP00311	2	Rosado
TAZ-4086	DTP00312	4	Normal
LLA-3046	DTP00313	3	Metal
LLA-5046	DTP00313	5	Circular
GOR-2182	DTP00314	2	Rosado
GOR-2183	DTP00315	2	Blanco
CAM-1069	DTP00316	1	XXL
CAM-2184	DTP00316	2	Amarillo
CAM-1070	DTP00317	1	M
CAM-2185	DTP00317	2	Verde
CAM-1071	DTP00318	1	M
CAM-2186	DTP00318	2	Verde
GOR-2187	DTP00319	2	Verde
TAZ-4087	DTP00320	4	Magica
TAZ-4088	DTP00321	4	Normal
TAZ-4089	DTP00322	4	Magica
TAZ-4090	DTP00323	4	Magica
LLA-3047	DTP00324	3	Metal
LLA-5047	DTP00324	5	Rectangular
TAZ-4091	DTP00325	4	Normal
GOR-2188	DTP00326	2	Gris
GOR-2189	DTP00327	2	Rosado
TAZ-4092	DTP00328	4	Magica
GOR-2190	DTP00329	2	Amarillo
LLA-3048	DTP00330	3	Metal
LLA-5048	DTP00330	5	Rectangular
GOR-2191	DTP00331	2	Blanco
GOR-2192	DTP00332	2	Negro
TAZ-4093	DTP00333	4	Normal
CAM-1072	DTP00334	1	14
CAM-2193	DTP00334	2	Azul
TAZ-4094	DTP00335	4	Magica
LLA-3049	DTP00336	3	Madera
LLA-5049	DTP00336	5	Corazon
GOR-2194	DTP00337	2	Negro
TAZ-4095	DTP00338	4	Magica
CAM-1073	DTP00339	1	4
CAM-2195	DTP00339	2	Verde
TAZ-4096	DTP00340	4	Normal
CAM-1074	DTP00341	1	14
CAM-2196	DTP00341	2	Blanco
TAZ-4097	DTP00342	4	Magica
CAM-1075	DTP00343	1	14
CAM-2197	DTP00343	2	Verde
CAM-1076	DTP00344	1	L
CAM-2198	DTP00344	2	Rosado
TAZ-4098	DTP00345	4	Magica
GOR-2199	DTP00346	2	Verde
TAZ-4099	DTP00347	4	Magica
GOR-2200	DTP00348	2	Rosado
GOR-2201	DTP00349	2	Morado
TER-2202	DTP00350	2	Rojo
TER-6016	DTP00350	6	Aluminio
TAZ-4100	DTP00351	4	Normal
LLA-3050	DTP00352	3	Metal
LLA-5050	DTP00352	5	Circular
CAM-1077	DTP00353	1	L
CAM-2203	DTP00353	2	Gris
TAZ-4101	DTP00354	4	Normal
GOR-2204	DTP00355	2	Amarillo
GOR-2205	DTP00356	2	Verde
LLA-3051	DTP00357	3	PVC
LLA-5051	DTP00357	5	Circular
GOR-2206	DTP00358	2	Blanco
GOR-2207	DTP00359	2	Gris
GOR-2208	DTP00360	2	Amarillo
GOR-2209	DTP00361	2	Rosado
TAZ-4102	DTP00362	4	Magica
CAM-1078	DTP00363	1	8
CAM-2210	DTP00363	2	Blanco
CAM-1079	DTP00364	1	L
CAM-2211	DTP00364	2	Negro
CAM-1080	DTP00365	1	M
CAM-2212	DTP00365	2	Morado
TAZ-4103	DTP00366	4	Magica
TAZ-4104	DTP00367	4	Magica
CAM-1081	DTP00368	1	14
CAM-2213	DTP00368	2	Rojo
TAZ-4105	DTP00369	4	Normal
GOR-2214	DTP00370	2	Amarillo
LLA-3052	DTP00371	3	Madera
LLA-5052	DTP00371	5	Circular
CAM-1082	DTP00372	1	M
CAM-2215	DTP00372	2	Amarillo
GOR-2216	DTP00373	2	Morado
LLA-3053	DTP00374	3	Madera
LLA-5053	DTP00374	5	Rectangular
GOR-2217	DTP00375	2	Gris
GOR-2218	DTP00376	2	Blanco
GOR-2219	DTP00377	2	Gris
LLA-3054	DTP00378	3	Madera
LLA-5054	DTP00378	5	Corazon
GOR-2220	DTP00379	2	Verde
GOR-2221	DTP00380	2	Verde
LLA-3055	DTP00381	3	Madera
LLA-5055	DTP00381	5	Circular
GOR-2222	DTP00382	2	Blanco
GOR-2223	DTP00383	2	Morado
TAZ-4106	DTP00384	4	Magica
GOR-2224	DTP00385	2	Verde
GOR-2225	DTP00386	2	Azul
CAM-1083	DTP00387	1	XXL
CAM-2226	DTP00387	2	Morado
TAZ-4107	DTP00388	4	Magica
TAZ-4108	DTP00389	4	Normal
GOR-2227	DTP00390	2	Rosado
GOR-2228	DTP00391	2	Gris
TAZ-4109	DTP00392	4	Normal
CAM-1084	DTP00393	1	XXL
CAM-2229	DTP00393	2	Verde
LLA-3056	DTP00394	3	Metal
LLA-5056	DTP00394	5	Corazon
TAZ-4110	DTP00395	4	Normal
GOR-2230	DTP00396	2	Verde
GOR-2231	DTP00397	2	Gris
LLA-3057	DTP00398	3	PVC
LLA-5057	DTP00398	5	Corazon
CAM-1085	DTP00399	1	L
CAM-2232	DTP00399	2	Negro
LLA-3058	DTP00400	3	PVC
LLA-5058	DTP00400	5	Corazon
LLA-3059	DTP00401	3	Metal
LLA-5059	DTP00401	5	Rectangular
LLA-3060	DTP00402	3	Madera
LLA-5060	DTP00402	5	Corazon
TAZ-4111	DTP00403	4	Normal
TER-2233	DTP00404	2	Azul
TER-6017	DTP00404	6	Plastico
GOR-2234	DTP00405	2	Azul
LLA-3061	DTP00406	3	PVC
LLA-5061	DTP00406	5	Corazon
GOR-2235	DTP00407	2	Negro
LLA-3062	DTP00408	3	Metal
LLA-5062	DTP00408	5	Circular
CAM-1086	DTP00409	1	6
CAM-2236	DTP00409	2	Azul
LLA-3063	DTP00410	3	PVC
LLA-5063	DTP00410	5	Rectangular
LLA-3064	DTP00411	3	Metal
LLA-5064	DTP00411	5	Corazon
LLA-3065	DTP00412	3	PVC
LLA-5065	DTP00412	5	Rectangular
LLA-3066	DTP00413	3	Madera
LLA-5066	DTP00413	5	Rectangular
CAM-1087	DTP00414	1	XL
CAM-2237	DTP00414	2	Morado
GOR-2238	DTP00415	2	Morado
TAZ-4112	DTP00416	4	Normal
GOR-2239	DTP00417	2	Rojo
LLA-3067	DTP00418	3	PVC
LLA-5067	DTP00418	5	Circular
CAM-1088	DTP00419	1	14
CAM-2240	DTP00419	2	Blanco
TAZ-4113	DTP00420	4	Normal
CAM-1089	DTP00421	1	M
CAM-2241	DTP00421	2	Rosado
GOR-2242	DTP00422	2	Verde
TER-2243	DTP00423	2	Rosado
TER-6018	DTP00423	6	Plastico
CAM-1090	DTP00424	1	XXL
CAM-2244	DTP00424	2	Verde
CAM-1091	DTP00425	1	M
CAM-2245	DTP00425	2	Verde
GOR-2246	DTP00426	2	Verde
TAZ-4114	DTP00427	4	Magica
GOR-2247	DTP00428	2	Azul
CAM-1092	DTP00429	1	8
CAM-2248	DTP00429	2	Amarillo
TAZ-4115	DTP00430	4	Magica
GOR-2249	DTP00431	2	Morado
TAZ-4116	DTP00432	4	Normal
TAZ-4117	DTP00433	4	Normal
GOR-2250	DTP00434	2	Verde
CAM-1093	DTP00435	1	6
CAM-2251	DTP00435	2	Rojo
LLA-3068	DTP00436	3	PVC
LLA-5068	DTP00436	5	Rectangular
LLA-3069	DTP00437	3	Metal
LLA-5069	DTP00437	5	Corazon
GOR-2252	DTP00438	2	Rojo
CAM-1094	DTP00439	1	4
CAM-2253	DTP00439	2	Amarillo
GOR-2254	DTP00440	2	Azul
GOR-2255	DTP00441	2	Rojo
CAM-1095	DTP00442	1	L
CAM-2256	DTP00442	2	Blanco
TAZ-4118	DTP00443	4	Normal
LLA-3070	DTP00444	3	Metal
LLA-5070	DTP00444	5	Circular
GOR-2257	DTP00445	2	Verde
TAZ-4119	DTP00446	4	Magica
CAM-1096	DTP00447	1	XXL
CAM-2258	DTP00447	2	Negro
TAZ-4120	DTP00448	4	Normal
TAZ-4121	DTP00449	4	Magica
CAM-1097	DTP00450	1	4
CAM-2259	DTP00450	2	Amarillo
LLA-3071	DTP00451	3	PVC
LLA-5071	DTP00451	5	Rectangular
LLA-3072	DTP00452	3	Metal
LLA-5072	DTP00452	5	Corazon
CAM-1098	DTP00453	1	L
CAM-2260	DTP00453	2	Rojo
TAZ-4122	DTP00454	4	Magica
TAZ-4123	DTP00455	4	Magica
GOR-2261	DTP00456	2	Negro
TAZ-4124	DTP00457	4	Normal
TAZ-4125	DTP00458	4	Normal
TAZ-4126	DTP00459	4	Normal
GOR-2262	DTP00460	2	Gris
TAZ-4127	DTP00461	4	Magica
GOR-2263	DTP00462	2	Morado
TAZ-4128	DTP00463	4	Magica
GOR-2264	DTP00464	2	Gris
GOR-2265	DTP00465	2	Morado
CAM-1099	DTP00466	1	L
CAM-2266	DTP00466	2	Rosado
TAZ-4129	DTP00467	4	Magica
CAM-1100	DTP00468	1	L
CAM-2267	DTP00468	2	Verde
GOR-2268	DTP00469	2	Negro
LLA-3073	DTP00470	3	Madera
LLA-5073	DTP00470	5	Circular
CAM-1101	DTP00471	1	M
CAM-2269	DTP00471	2	Azul
CAM-1102	DTP00472	1	M
CAM-2270	DTP00472	2	Negro
CAM-1103	DTP00473	1	14
CAM-2271	DTP00473	2	Negro
CAM-1104	DTP00474	1	14
CAM-2272	DTP00474	2	Gris
LLA-3074	DTP00475	3	PVC
LLA-5074	DTP00475	5	Corazon
GOR-2273	DTP00476	2	Negro
GOR-2274	DTP00477	2	Amarillo
CAM-1105	DTP00478	1	L
CAM-2275	DTP00478	2	Blanco
TAZ-4130	DTP00479	4	Magica
CAM-1106	DTP00480	1	6
CAM-2276	DTP00480	2	Negro
TER-2277	DTP00481	2	Blanco
TER-6019	DTP00481	6	Plastico
GOR-2278	DTP00482	2	Morado
TAZ-4131	DTP00483	4	Normal
LLA-3075	DTP00484	3	Madera
LLA-5075	DTP00484	5	Rectangular
CAM-1107	DTP00485	1	L
CAM-2279	DTP00485	2	Amarillo
TAZ-4132	DTP00486	4	Magica
TAZ-4133	DTP00487	4	Normal
GOR-2280	DTP00488	2	Morado
GOR-2281	DTP00489	2	Gris
LLA-3076	DTP00490	3	Madera
LLA-5076	DTP00490	5	Corazon
GOR-2282	DTP00491	2	Rojo
CAM-1108	DTP00492	1	S
CAM-2283	DTP00492	2	Verde
GOR-2284	DTP00493	2	Rojo
TAZ-4134	DTP00494	4	Magica
CAM-1109	DTP00495	1	S
CAM-2285	DTP00495	2	Rosado
TAZ-4135	DTP00496	4	Magica
CAM-1110	DTP00497	1	S
CAM-2286	DTP00497	2	Verde
CAM-1111	DTP00498	1	XL
CAM-2287	DTP00498	2	Negro
CAM-1112	DTP00499	1	S
CAM-2288	DTP00499	2	Rosado
TAZ-4136	DTP00500	4	Magica
GOR-2289	DTP00501	2	Azul
TAZ-4137	DTP00502	4	Magica
LLA-3077	DTP00503	3	Metal
LLA-5077	DTP00503	5	Rectangular
CAM-1113	DTP00504	1	M
CAM-2290	DTP00504	2	Rosado
TAZ-4138	DTP00505	4	Magica
GOR-2291	DTP00506	2	Rojo
LLA-3078	DTP00507	3	PVC
LLA-5078	DTP00507	5	Circular
GOR-2292	DTP00508	2	Gris
TAZ-4139	DTP00509	4	Normal
LLA-3079	DTP00510	3	Madera
LLA-5079	DTP00510	5	Rectangular
CAM-1114	DTP00511	1	S
CAM-2293	DTP00511	2	Rosado
TAZ-4140	DTP00512	4	Magica
LLA-3080	DTP00513	3	Madera
LLA-5080	DTP00513	5	Rectangular
TAZ-4141	DTP00514	4	Normal
TAZ-4142	DTP00515	4	Magica
CAM-1115	DTP00516	1	4
CAM-2294	DTP00516	2	Blanco
GOR-2295	DTP00517	2	Rosado
TAZ-4143	DTP00518	4	Magica
CAM-1116	DTP00519	1	L
CAM-2296	DTP00519	2	Morado
TER-2297	DTP00520	2	Blanco
TER-6020	DTP00520	6	Plastico
CAM-1117	DTP00521	1	M
CAM-2298	DTP00521	2	Morado
LLA-3081	DTP00522	3	PVC
LLA-5081	DTP00522	5	Rectangular
CAM-1118	DTP00523	1	6
CAM-2299	DTP00523	2	Gris
GOR-2300	DTP00524	2	Morado
GOR-2301	DTP00525	2	Verde
LLA-3082	DTP00526	3	Madera
LLA-5082	DTP00526	5	Corazon
TAZ-4144	DTP00527	4	Magica
CAM-1119	DTP00528	1	12
CAM-2302	DTP00528	2	Gris
TER-2303	DTP00529	2	Verde
TER-6021	DTP00529	6	Plastico
TAZ-4145	DTP00530	4	Normal
TAZ-4146	DTP00531	4	Magica
TAZ-4147	DTP00532	4	Magica
TAZ-4148	DTP00533	4	Magica
TAZ-4149	DTP00534	4	Normal
TAZ-4150	DTP00535	4	Magica
CAM-1120	DTP00536	1	XXL
CAM-2304	DTP00536	2	Morado
GOR-2305	DTP00537	2	Gris
TAZ-4151	DTP00538	4	Normal
LLA-3083	DTP00539	3	PVC
LLA-5083	DTP00539	5	Circular
CAM-1121	DTP00540	1	XXL
CAM-2306	DTP00540	2	Gris
GOR-2307	DTP00541	2	Blanco
TAZ-4152	DTP00542	4	Normal
TAZ-4153	DTP00543	4	Normal
LLA-3084	DTP00544	3	PVC
LLA-5084	DTP00544	5	Corazon
GOR-2308	DTP00545	2	Rojo
GOR-2309	DTP00546	2	Gris
CAM-1122	DTP00547	1	L
CAM-2310	DTP00547	2	Rojo
GOR-2311	DTP00548	2	Blanco
GOR-2312	DTP00549	2	Verde
CAM-1123	DTP00550	1	M
CAM-2313	DTP00550	2	Amarillo
LLA-3085	DTP00551	3	Metal
LLA-5085	DTP00551	5	Corazon
CAM-1124	DTP00552	1	L
CAM-2314	DTP00552	2	Rojo
LLA-3086	DTP00553	3	Madera
LLA-5086	DTP00553	5	Corazon
CAM-1125	DTP00554	1	6
CAM-2315	DTP00554	2	Gris
TAZ-4154	DTP00555	4	Magica
TAZ-4155	DTP00556	4	Magica
GOR-2316	DTP00557	2	Rojo
LLA-3087	DTP00558	3	PVC
LLA-5087	DTP00558	5	Rectangular
GOR-2317	DTP00559	2	Rosado
LLA-3088	DTP00560	3	Madera
LLA-5088	DTP00560	5	Rectangular
TAZ-4156	DTP00561	4	Magica
CAM-1126	DTP00562	1	14
CAM-2318	DTP00562	2	Morado
LLA-3089	DTP00563	3	Metal
LLA-5089	DTP00563	5	Circular
CAM-1127	DTP00564	1	6
CAM-2319	DTP00564	2	Rosado
TAZ-4157	DTP00565	4	Magica
TER-2320	DTP00566	2	Amarillo
TER-6022	DTP00566	6	Plastico
LLA-3090	DTP00567	3	PVC
LLA-5090	DTP00567	5	Circular
GOR-2321	DTP00568	2	Blanco
TAZ-4158	DTP00569	4	Normal
GOR-2322	DTP00570	2	Azul
GOR-2323	DTP00571	2	Gris
TAZ-4159	DTP00572	4	Magica
LLA-3091	DTP00573	3	PVC
LLA-5091	DTP00573	5	Corazon
TAZ-4160	DTP00574	4	Magica
CAM-1128	DTP00575	1	XXL
CAM-2324	DTP00575	2	Morado
CAM-1129	DTP00576	1	4
CAM-2325	DTP00576	2	Gris
LLA-3092	DTP00577	3	Madera
LLA-5092	DTP00577	5	Rectangular
LLA-3093	DTP00578	3	Madera
LLA-5093	DTP00578	5	Circular
CAM-1130	DTP00579	1	L
CAM-2326	DTP00579	2	Blanco
TAZ-4161	DTP00580	4	Normal
TAZ-4162	DTP00581	4	Magica
CAM-1131	DTP00582	1	12
CAM-2327	DTP00582	2	Verde
TAZ-4163	DTP00583	4	Normal
GOR-2328	DTP00584	2	Blanco
GOR-2329	DTP00585	2	Rojo
TER-2330	DTP00586	2	Azul
TER-6023	DTP00586	6	Aluminio
TAZ-4164	DTP00587	4	Magica
GOR-2331	DTP00588	2	Negro
TAZ-4165	DTP00589	4	Normal
CAM-1132	DTP00590	1	12
CAM-2332	DTP00590	2	Amarillo
TAZ-4166	DTP00591	4	Magica
TAZ-4167	DTP00592	4	Magica
GOR-2333	DTP00593	2	Rojo
TAZ-4168	DTP00594	4	Magica
TAZ-4169	DTP00595	4	Magica
TAZ-4170	DTP00596	4	Normal
TAZ-4171	DTP00597	4	Normal
GOR-2334	DTP00598	2	Rojo
TAZ-4172	DTP00599	4	Magica
TAZ-4173	DTP00600	4	Normal
LLA-3094	DTP00601	3	PVC
LLA-5094	DTP00601	5	Rectangular
LLA-3095	DTP00602	3	PVC
LLA-5095	DTP00602	5	Corazon
CAM-1133	DTP00603	1	XL
CAM-2335	DTP00603	2	Azul
GOR-2336	DTP00604	2	Amarillo
GOR-2337	DTP00605	2	Azul
CAM-1134	DTP00606	1	6
CAM-2338	DTP00606	2	Negro
GOR-2339	DTP00607	2	Negro
CAM-1135	DTP00608	1	M
CAM-2340	DTP00608	2	Morado
TAZ-4174	DTP00609	4	Magica
TAZ-4175	DTP00610	4	Normal
LLA-3096	DTP00611	3	PVC
LLA-5096	DTP00611	5	Corazon
CAM-1136	DTP00612	1	4
CAM-2341	DTP00612	2	Gris
CAM-1137	DTP00613	1	8
CAM-2342	DTP00613	2	Rojo
TAZ-4176	DTP00614	4	Normal
TAZ-4177	DTP00615	4	Magica
TAZ-4178	DTP00616	4	Magica
GOR-2343	DTP00617	2	Morado
LLA-3097	DTP00618	3	PVC
LLA-5097	DTP00618	5	Rectangular
GOR-2344	DTP00619	2	Azul
LLA-3098	DTP00620	3	Madera
LLA-5098	DTP00620	5	Corazon
TAZ-4179	DTP00621	4	Normal
GOR-2345	DTP00622	2	Blanco
CAM-1138	DTP00623	1	4
CAM-2346	DTP00623	2	Amarillo
TAZ-4180	DTP00624	4	Magica
CAM-1139	DTP00625	1	XL
CAM-2347	DTP00625	2	Verde
CAM-1140	DTP00626	1	8
CAM-2348	DTP00626	2	Gris
LLA-3099	DTP00627	3	PVC
LLA-5099	DTP00627	5	Corazon
LLA-3100	DTP00628	3	PVC
LLA-5100	DTP00628	5	Circular
GOR-2349	DTP00629	2	Rojo
CAM-1141	DTP00630	1	XL
CAM-2350	DTP00630	2	Morado
GOR-2351	DTP00631	2	Morado
GOR-2352	DTP00632	2	Azul
GOR-2353	DTP00633	2	Morado
CAM-1142	DTP00634	1	8
CAM-2354	DTP00634	2	Morado
GOR-2355	DTP00635	2	Verde
TAZ-4181	DTP00636	4	Magica
TAZ-4182	DTP00637	4	Magica
LLA-3101	DTP00638	3	Metal
LLA-5101	DTP00638	5	Rectangular
TAZ-4183	DTP00639	4	Normal
GOR-2356	DTP00640	2	Negro
TAZ-4184	DTP00641	4	Normal
LLA-3102	DTP00642	3	Madera
LLA-5102	DTP00642	5	Circular
TAZ-4185	DTP00643	4	Normal
CAM-1143	DTP00644	1	8
CAM-2357	DTP00644	2	Verde
TAZ-4186	DTP00645	4	Magica
CAM-1144	DTP00646	1	6
CAM-2358	DTP00646	2	Rojo
TAZ-4187	DTP00647	4	Normal
TAZ-4188	DTP00648	4	Normal
TAZ-4189	DTP00649	4	Magica
GOR-2359	DTP00650	2	Amarillo
TAZ-4190	DTP00651	4	Normal
TER-2360	DTP00652	2	Amarillo
TER-6024	DTP00652	6	Aluminio
TAZ-4191	DTP00653	4	Magica
LLA-3103	DTP00654	3	PVC
LLA-5103	DTP00654	5	Corazon
GOR-2361	DTP00655	2	Blanco
CAM-1145	DTP00656	1	M
CAM-2362	DTP00656	2	Rosado
CAM-1146	DTP00657	1	L
CAM-2363	DTP00657	2	Morado
CAM-1147	DTP00658	1	M
CAM-2364	DTP00658	2	Verde
GOR-2365	DTP00659	2	Rojo
GOR-2366	DTP00660	2	Negro
TAZ-4192	DTP00661	4	Normal
CAM-1148	DTP00662	1	L
CAM-2367	DTP00662	2	Amarillo
GOR-2368	DTP00663	2	Negro
CAM-1149	DTP00664	1	L
CAM-2369	DTP00664	2	Amarillo
GOR-2370	DTP00665	2	Gris
GOR-2371	DTP00666	2	Negro
GOR-2372	DTP00667	2	Azul
GOR-2373	DTP00668	2	Amarillo
CAM-1150	DTP00669	1	S
CAM-2374	DTP00669	2	Amarillo
TAZ-4193	DTP00670	4	Magica
TAZ-4194	DTP00671	4	Magica
LLA-3104	DTP00672	3	Metal
LLA-5104	DTP00672	5	Rectangular
CAM-1151	DTP00673	1	XXL
CAM-2375	DTP00673	2	Morado
CAM-1152	DTP00674	1	4
CAM-2376	DTP00674	2	Gris
TER-2377	DTP00675	2	Negro
TER-6025	DTP00675	6	Plastico
CAM-1153	DTP00676	1	12
CAM-2378	DTP00676	2	Negro
LLA-3105	DTP00677	3	Metal
LLA-5105	DTP00677	5	Corazon
CAM-1154	DTP00678	1	14
CAM-2379	DTP00678	2	Amarillo
CAM-1155	DTP00679	1	14
CAM-2380	DTP00679	2	Gris
TAZ-4195	DTP00680	4	Magica
GOR-2381	DTP00681	2	Negro
LLA-3106	DTP00682	3	Metal
LLA-5106	DTP00682	5	Corazon
TAZ-4196	DTP00683	4	Normal
TAZ-4197	DTP00684	4	Normal
TAZ-4198	DTP00685	4	Magica
LLA-3107	DTP00686	3	Madera
LLA-5107	DTP00686	5	Rectangular
GOR-2382	DTP00687	2	Rojo
TAZ-4199	DTP00688	4	Normal
GOR-2383	DTP00689	2	Rosado
LLA-3108	DTP00690	3	Madera
LLA-5108	DTP00690	5	Circular
CAM-1156	DTP00691	1	M
CAM-2384	DTP00691	2	Gris
GOR-2385	DTP00692	2	Rojo
TAZ-4200	DTP00693	4	Magica
TAZ-4201	DTP00694	4	Magica
TAZ-4202	DTP00695	4	Magica
CAM-1157	DTP00696	1	8
CAM-2386	DTP00696	2	Rojo
LLA-3109	DTP00697	3	PVC
LLA-5109	DTP00697	5	Circular
TAZ-4203	DTP00698	4	Normal
GOR-2387	DTP00699	2	Blanco
TAZ-4204	DTP00700	4	Magica
LLA-3110	DTP00701	3	Madera
LLA-5110	DTP00701	5	Rectangular
CAM-1158	DTP00702	1	XL
CAM-2388	DTP00702	2	Rojo
CAM-1159	DTP00703	1	XXL
CAM-2389	DTP00703	2	Amarillo
LLA-3111	DTP00704	3	Metal
LLA-5111	DTP00704	5	Rectangular
TAZ-4205	DTP00705	4	Normal
GOR-2390	DTP00706	2	Negro
CAM-1160	DTP00707	1	S
CAM-2391	DTP00707	2	Morado
TAZ-4206	DTP00708	4	Normal
TAZ-4207	DTP00709	4	Magica
TAZ-4208	DTP00710	4	Magica
TER-2392	DTP00711	2	Blanco
TER-6026	DTP00711	6	Plastico
TAZ-4209	DTP00712	4	Normal
GOR-2393	DTP00713	2	Rojo
CAM-1161	DTP00714	1	S
CAM-2394	DTP00714	2	Morado
GOR-2395	DTP00715	2	Verde
GOR-2396	DTP00716	2	Rojo
TAZ-4210	DTP00717	4	Normal
CAM-1162	DTP00718	1	XL
CAM-2397	DTP00718	2	Azul
GOR-2398	DTP00719	2	Gris
CAM-1163	DTP00720	1	14
CAM-2399	DTP00720	2	Rojo
GOR-2400	DTP00721	2	Azul
CAM-1164	DTP00722	1	S
CAM-2401	DTP00722	2	Morado
CAM-1165	DTP00723	1	L
CAM-2402	DTP00723	2	Amarillo
CAM-1166	DTP00724	1	S
CAM-2403	DTP00724	2	Rojo
TAZ-4211	DTP00725	4	Magica
CAM-1167	DTP00726	1	XXL
CAM-2404	DTP00726	2	Negro
GOR-2405	DTP00727	2	Rosado
CAM-1168	DTP00728	1	4
CAM-2406	DTP00728	2	Negro
CAM-1169	DTP00729	1	8
CAM-2407	DTP00729	2	Rosado
TAZ-4212	DTP00730	4	Normal
LLA-3112	DTP00731	3	PVC
LLA-5112	DTP00731	5	Corazon
LLA-3113	DTP00732	3	Madera
LLA-5113	DTP00732	5	Circular
CAM-1170	DTP00733	1	12
CAM-2408	DTP00733	2	Negro
LLA-3114	DTP00734	3	PVC
LLA-5114	DTP00734	5	Rectangular
TAZ-4213	DTP00735	4	Magica
CAM-1171	DTP00736	1	XL
CAM-2409	DTP00736	2	Amarillo
CAM-1172	DTP00737	1	M
CAM-2410	DTP00737	2	Verde
GOR-2411	DTP00738	2	Blanco
TAZ-4214	DTP00739	4	Magica
TAZ-4215	DTP00740	4	Magica
LLA-3115	DTP00741	3	PVC
LLA-5115	DTP00741	5	Corazon
TAZ-4216	DTP00742	4	Magica
LLA-3116	DTP00743	3	Madera
LLA-5116	DTP00743	5	Corazon
TAZ-4217	DTP00744	4	Normal
CAM-1173	DTP00745	1	S
CAM-2412	DTP00745	2	Rosado
TER-2413	DTP00746	2	Azul
TER-6027	DTP00746	6	Aluminio
GOR-2414	DTP00747	2	Amarillo
TAZ-4218	DTP00748	4	Normal
LLA-3117	DTP00749	3	PVC
LLA-5117	DTP00749	5	Corazon
TAZ-4219	DTP00750	4	Normal
CAM-1174	DTP00751	1	S
CAM-2415	DTP00751	2	Verde
GOR-2416	DTP00752	2	Morado
LLA-3118	DTP00753	3	PVC
LLA-5118	DTP00753	5	Rectangular
GOR-2417	DTP00754	2	Verde
CAM-1175	DTP00755	1	14
CAM-2418	DTP00755	2	Amarillo
GOR-2419	DTP00756	2	Blanco
TER-2420	DTP00757	2	Azul
TER-6028	DTP00757	6	Aluminio
TAZ-4220	DTP00758	4	Magica
GOR-2421	DTP00759	2	Blanco
GOR-2422	DTP00760	2	Gris
LLA-3119	DTP00761	3	Metal
LLA-5119	DTP00761	5	Rectangular
GOR-2423	DTP00762	2	Rojo
GOR-2424	DTP00763	2	Negro
LLA-3120	DTP00764	3	Madera
LLA-5120	DTP00764	5	Circular
CAM-1176	DTP00765	1	8
CAM-2425	DTP00765	2	Rosado
GOR-2426	DTP00766	2	Azul
GOR-2427	DTP00767	2	Negro
GOR-2428	DTP00768	2	Rojo
TER-2429	DTP00769	2	Rojo
TER-6029	DTP00769	6	Aluminio
CAM-1177	DTP00770	1	8
CAM-2430	DTP00770	2	Gris
GOR-2431	DTP00771	2	Azul
CAM-1178	DTP00772	1	12
CAM-2432	DTP00772	2	Verde
LLA-3121	DTP00773	3	Madera
LLA-5121	DTP00773	5	Corazon
TAZ-4221	DTP00774	4	Normal
TAZ-4222	DTP00775	4	Normal
CAM-1179	DTP00776	1	L
CAM-2433	DTP00776	2	Rojo
CAM-1180	DTP00777	1	8
CAM-2434	DTP00777	2	Amarillo
TAZ-4223	DTP00778	4	Magica
TER-2435	DTP00779	2	Rojo
TER-6030	DTP00779	6	Aluminio
CAM-1181	DTP00780	1	12
CAM-2436	DTP00780	2	Rojo
TAZ-4224	DTP00781	4	Normal
TAZ-4225	DTP00782	4	Magica
GOR-2437	DTP00783	2	Verde
CAM-1182	DTP00784	1	XXL
CAM-2438	DTP00784	2	Gris
GOR-2439	DTP00785	2	Azul
GOR-2440	DTP00786	2	Verde
TER-2441	DTP00787	2	Rojo
TER-6031	DTP00787	6	Plastico
TAZ-4226	DTP00788	4	Normal
TAZ-4227	DTP00789	4	Magica
LLA-3122	DTP00790	3	Madera
LLA-5122	DTP00790	5	Corazon
CAM-1183	DTP00791	1	M
CAM-2442	DTP00791	2	Verde
GOR-2443	DTP00792	2	Amarillo
CAM-1184	DTP00793	1	M
CAM-2444	DTP00793	2	Rosado
TER-2445	DTP00794	2	Rojo
TER-6032	DTP00794	6	Plastico
LLA-3123	DTP00795	3	Metal
LLA-5123	DTP00795	5	Corazon
LLA-3124	DTP00796	3	Metal
LLA-5124	DTP00796	5	Corazon
CAM-1185	DTP00797	1	M
CAM-2446	DTP00797	2	Azul
LLA-3125	DTP00798	3	Madera
LLA-5125	DTP00798	5	Rectangular
LLA-3126	DTP00799	3	Madera
LLA-5126	DTP00799	5	Corazon
LLA-3127	DTP00800	3	PVC
LLA-5127	DTP00800	5	Corazon
TAZ-4228	DTP00801	4	Normal
TAZ-4229	DTP00802	4	Normal
GOR-2447	DTP00803	2	Negro
TER-2448	DTP00804	2	Morado
TER-6033	DTP00804	6	Plastico
CAM-1186	DTP00805	1	8
CAM-2449	DTP00805	2	Verde
TAZ-4230	DTP00806	4	Normal
GOR-2450	DTP00807	2	Negro
TAZ-4231	DTP00808	4	Normal
LLA-3128	DTP00809	3	PVC
LLA-5128	DTP00809	5	Rectangular
GOR-2451	DTP00810	2	Blanco
TER-2452	DTP00811	2	Morado
TER-6034	DTP00811	6	Plastico
GOR-2453	DTP00812	2	Blanco
TAZ-4232	DTP00813	4	Normal
LLA-3129	DTP00814	3	Metal
LLA-5129	DTP00814	5	Rectangular
CAM-1187	DTP00815	1	8
CAM-2454	DTP00815	2	Negro
TAZ-4233	DTP00816	4	Magica
GOR-2455	DTP00817	2	Blanco
TAZ-4234	DTP00818	4	Normal
GOR-2456	DTP00819	2	Blanco
LLA-3130	DTP00820	3	Metal
LLA-5130	DTP00820	5	Corazon
TAZ-4235	DTP00821	4	Normal
GOR-2457	DTP00822	2	Azul
LLA-3131	DTP00823	3	Madera
LLA-5131	DTP00823	5	Rectangular
GOR-2458	DTP00824	2	Verde
GOR-2459	DTP00825	2	Verde
CAM-1188	DTP00826	1	4
CAM-2460	DTP00826	2	Rojo
CAM-1189	DTP00827	1	14
CAM-2461	DTP00827	2	Blanco
GOR-2462	DTP00828	2	Blanco
GOR-2463	DTP00829	2	Azul
TAZ-4236	DTP00830	4	Normal
LLA-3132	DTP00831	3	Madera
LLA-5132	DTP00831	5	Rectangular
LLA-3133	DTP00832	3	Madera
LLA-5133	DTP00832	5	Circular
CAM-1190	DTP00833	1	M
CAM-2464	DTP00833	2	Gris
CAM-1191	DTP00834	1	6
CAM-2465	DTP00834	2	Azul
TER-2466	DTP00835	2	Rosado
TER-6035	DTP00835	6	Plastico
TER-2467	DTP00836	2	Blanco
TER-6036	DTP00836	6	Plastico
GOR-2468	DTP00837	2	Rosado
TAZ-4237	DTP00838	4	Normal
LLA-3134	DTP00839	3	Metal
LLA-5134	DTP00839	5	Corazon
LLA-3135	DTP00840	3	Metal
LLA-5135	DTP00840	5	Corazon
GOR-2469	DTP00841	2	Morado
GOR-2470	DTP00842	2	Gris
TAZ-4238	DTP00843	4	Normal
LLA-3136	DTP00844	3	PVC
LLA-5136	DTP00844	5	Circular
TAZ-4239	DTP00845	4	Magica
TAZ-4240	DTP00846	4	Normal
GOR-2471	DTP00847	2	Amarillo
CAM-1192	DTP00848	1	M
CAM-2472	DTP00848	2	Blanco
CAM-1193	DTP00849	1	4
CAM-2473	DTP00849	2	Azul
LLA-3137	DTP00850	3	PVC
LLA-5137	DTP00850	5	Circular
CAM-1194	DTP00851	1	S
CAM-2474	DTP00851	2	Rosado
TAZ-4241	DTP00852	4	Normal
GOR-2475	DTP00853	2	Gris
GOR-2476	DTP00854	2	Negro
LLA-3138	DTP00855	3	Metal
LLA-5138	DTP00855	5	Rectangular
LLA-3139	DTP00856	3	PVC
LLA-5139	DTP00856	5	Circular
TAZ-4242	DTP00857	4	Normal
LLA-3140	DTP00858	3	PVC
LLA-5140	DTP00858	5	Corazon
TER-2477	DTP00859	2	Rojo
TER-6037	DTP00859	6	Plastico
CAM-1195	DTP00860	1	6
CAM-2478	DTP00860	2	Gris
TER-2479	DTP00861	2	Azul
TER-6038	DTP00861	6	Aluminio
TAZ-4243	DTP00862	4	Magica
TAZ-4244	DTP00863	4	Normal
LLA-3141	DTP00864	3	Madera
LLA-5141	DTP00864	5	Rectangular
TAZ-4245	DTP00865	4	Normal
TER-2480	DTP00866	2	Negro
TER-6039	DTP00866	6	Aluminio
LLA-3142	DTP00867	3	PVC
LLA-5142	DTP00867	5	Corazon
TAZ-4246	DTP00868	4	Magica
TAZ-4247	DTP00869	4	Magica
LLA-3143	DTP00870	3	Madera
LLA-5143	DTP00870	5	Circular
CAM-1196	DTP00871	1	XL
CAM-2481	DTP00871	2	Negro
TAZ-4248	DTP00872	4	Normal
GOR-2482	DTP00873	2	Azul
TAZ-4249	DTP00874	4	Normal
TAZ-4250	DTP00875	4	Magica
CAM-1197	DTP00876	1	12
CAM-2483	DTP00876	2	Gris
LLA-3144	DTP00877	3	Metal
LLA-5144	DTP00877	5	Rectangular
LLA-3145	DTP00878	3	Metal
LLA-5145	DTP00878	5	Corazon
TAZ-4251	DTP00879	4	Normal
GOR-2484	DTP00880	2	Rosado
GOR-2485	DTP00881	2	Negro
GOR-2486	DTP00882	2	Amarillo
LLA-3146	DTP00883	3	PVC
LLA-5146	DTP00883	5	Corazon
GOR-2487	DTP00884	2	Blanco
CAM-1198	DTP00885	1	S
CAM-2488	DTP00885	2	Blanco
GOR-2489	DTP00886	2	Rosado
LLA-3147	DTP00887	3	Madera
LLA-5147	DTP00887	5	Circular
CAM-1199	DTP00888	1	6
CAM-2490	DTP00888	2	Negro
TAZ-4252	DTP00889	4	Magica
CAM-1200	DTP00890	1	XL
CAM-2491	DTP00890	2	Verde
CAM-1201	DTP00891	1	4
CAM-2492	DTP00891	2	Blanco
CAM-1202	DTP00892	1	6
CAM-2493	DTP00892	2	Amarillo
LLA-3148	DTP00893	3	Metal
LLA-5148	DTP00893	5	Rectangular
GOR-2494	DTP00894	2	Gris
TAZ-4253	DTP00895	4	Normal
CAM-1203	DTP00896	1	12
CAM-2495	DTP00896	2	Rosado
GOR-2496	DTP00897	2	Gris
LLA-3149	DTP00898	3	Madera
LLA-5149	DTP00898	5	Corazon
TER-2497	DTP00899	2	Gris
TER-6040	DTP00899	6	Plastico
LLA-3150	DTP00900	3	PVC
LLA-5150	DTP00900	5	Rectangular
GOR-2498	DTP00901	2	Amarillo
TAZ-4254	DTP00902	4	Magica
LLA-3151	DTP00903	3	Metal
LLA-5151	DTP00903	5	Corazon
LLA-3152	DTP00904	3	Madera
LLA-5152	DTP00904	5	Corazon
CAM-1204	DTP00905	1	6
CAM-2499	DTP00905	2	Negro
CAM-1205	DTP00906	1	XL
CAM-2500	DTP00906	2	Amarillo
CAM-1206	DTP00907	1	S
CAM-2501	DTP00907	2	Blanco
TAZ-4255	DTP00908	4	Magica
LLA-3153	DTP00909	3	PVC
LLA-5153	DTP00909	5	Rectangular
LLA-3154	DTP00910	3	Madera
LLA-5154	DTP00910	5	Corazon
GOR-2502	DTP00911	2	Blanco
TAZ-4256	DTP00912	4	Magica
GOR-2503	DTP00913	2	Blanco
GOR-2504	DTP00914	2	Negro
GOR-2505	DTP00915	2	Morado
TAZ-4257	DTP00916	4	Normal
GOR-2506	DTP00917	2	Blanco
CAM-1207	DTP00918	1	S
CAM-2507	DTP00918	2	Gris
TAZ-4258	DTP00919	4	Normal
TAZ-4259	DTP00920	4	Normal
LLA-3155	DTP00921	3	Madera
LLA-5155	DTP00921	5	Circular
LLA-3156	DTP00922	3	PVC
LLA-5156	DTP00922	5	Corazon
GOR-2508	DTP00923	2	Amarillo
TAZ-4260	DTP00924	4	Normal
CAM-1208	DTP00925	1	XXL
CAM-2509	DTP00925	2	Azul
GOR-2510	DTP00926	2	Azul
GOR-2511	DTP00927	2	Verde
GOR-2512	DTP00928	2	Rosado
GOR-2513	DTP00929	2	Morado
GOR-2514	DTP00930	2	Blanco
TAZ-4261	DTP00931	4	Magica
TAZ-4262	DTP00932	4	Normal
CAM-1209	DTP00933	1	8
CAM-2515	DTP00933	2	Amarillo
CAM-1210	DTP00934	1	S
CAM-2516	DTP00934	2	Blanco
TAZ-4263	DTP00935	4	Magica
LLA-3157	DTP00936	3	PVC
LLA-5157	DTP00936	5	Corazon
TAZ-4264	DTP00937	4	Normal
CAM-1211	DTP00938	1	XL
CAM-2517	DTP00938	2	Azul
GOR-2518	DTP00939	2	Amarillo
GOR-2519	DTP00940	2	Azul
GOR-2520	DTP00941	2	Gris
GOR-2521	DTP00942	2	Morado
GOR-2522	DTP00943	2	Verde
CAM-1212	DTP00944	1	14
CAM-2523	DTP00944	2	Morado
GOR-2524	DTP00945	2	Azul
TAZ-4265	DTP00946	4	Magica
CAM-1213	DTP00947	1	8
CAM-2525	DTP00947	2	Gris
GOR-2526	DTP00948	2	Amarillo
GOR-2527	DTP00949	2	Rojo
LLA-3158	DTP00950	3	Metal
LLA-5158	DTP00950	5	Corazon
GOR-2528	DTP00951	2	Azul
TAZ-4266	DTP00952	4	Magica
TAZ-4267	DTP00953	4	Magica
GOR-2529	DTP00954	2	Amarillo
TAZ-4268	DTP00955	4	Normal
GOR-2530	DTP00956	2	Morado
GOR-2531	DTP00957	2	Azul
TER-2532	DTP00958	2	Rosado
TER-6041	DTP00958	6	Aluminio
LLA-3159	DTP00959	3	Madera
LLA-5159	DTP00959	5	Circular
GOR-2533	DTP00960	2	Blanco
LLA-3160	DTP00961	3	PVC
LLA-5160	DTP00961	5	Corazon
CAM-1214	DTP00962	1	XL
CAM-2534	DTP00962	2	Amarillo
LLA-3161	DTP00963	3	PVC
LLA-5161	DTP00963	5	Circular
GOR-2535	DTP00964	2	Gris
CAM-1215	DTP00965	1	XL
CAM-2536	DTP00965	2	Azul
GOR-2537	DTP00966	2	Negro
TER-2538	DTP00967	2	Gris
TER-6042	DTP00967	6	Plastico
TAZ-4269	DTP00968	4	Magica
GOR-2539	DTP00969	2	Amarillo
GOR-2540	DTP00970	2	Rojo
GOR-2541	DTP00971	2	Rojo
GOR-2542	DTP00972	2	Azul
GOR-2543	DTP00973	2	Blanco
TAZ-4270	DTP00974	4	Magica
TAZ-4271	DTP00975	4	Magica
TAZ-4272	DTP00976	4	Magica
TAZ-4273	DTP00977	4	Magica
LLA-3162	DTP00978	3	PVC
LLA-5162	DTP00978	5	Rectangular
CAM-1216	DTP00979	1	L
CAM-2544	DTP00979	2	Verde
GOR-2545	DTP00980	2	Gris
TAZ-4274	DTP00981	4	Normal
GOR-2546	DTP00982	2	Rojo
TAZ-4275	DTP00983	4	Normal
TAZ-4276	DTP00984	4	Normal
TER-2547	DTP00985	2	Blanco
TER-6043	DTP00985	6	Plastico
TAZ-4277	DTP00986	4	Magica
LLA-3163	DTP00987	3	Metal
LLA-5163	DTP00987	5	Corazon
TER-2548	DTP00988	2	Morado
TER-6044	DTP00988	6	Aluminio
TAZ-4278	DTP00989	4	Normal
CAM-1217	DTP00990	1	8
CAM-2549	DTP00990	2	Rosado
LLA-3164	DTP00991	3	Madera
LLA-5164	DTP00991	5	Corazon
TAZ-4279	DTP00992	4	Magica
TAZ-4280	DTP00993	4	Normal
CAM-1218	DTP00994	1	M
CAM-2550	DTP00994	2	Rosado
GOR-2551	DTP00995	2	Verde
GOR-2552	DTP00996	2	Amarillo
LLA-3165	DTP00997	3	PVC
LLA-5165	DTP00997	5	Rectangular
GOR-2553	DTP00998	2	Rosado
GOR-2554	DTP00999	2	Azul
TAZ-4281	DTP01000	4	Magica
TAZ-4282	DTP01001	4	Magica
TAZ-4283	DTP01002	4	Magica
GOR-2555	DTP01003	2	Amarillo
TER-2556	DTP01004	2	Negro
TER-6045	DTP01004	6	Aluminio
TAZ-4284	DTP01005	4	Magica
TER-2557	DTP01006	2	Amarillo
TER-6046	DTP01006	6	Aluminio
GOR-2558	DTP01007	2	Rojo
LLA-3166	DTP01008	3	PVC
LLA-5166	DTP01008	5	Corazon
TAZ-4285	DTP01009	4	Magica
TAZ-4286	DTP01010	4	Normal
GOR-2559	DTP01011	2	Morado
LLA-3167	DTP01012	3	PVC
LLA-5167	DTP01012	5	Rectangular
GOR-2560	DTP01013	2	Negro
TAZ-4287	DTP01014	4	Normal
TAZ-4288	DTP01015	4	Normal
TAZ-4289	DTP01016	4	Normal
TER-2561	DTP01017	2	Verde
TER-6047	DTP01017	6	Plastico
GOR-2562	DTP01018	2	Verde
LLA-3168	DTP01019	3	Metal
LLA-5168	DTP01019	5	Circular
CAM-1219	DTP01020	1	4
CAM-2563	DTP01020	2	Rojo
TER-2564	DTP01021	2	Verde
TER-6048	DTP01021	6	Aluminio
LLA-3169	DTP01022	3	Metal
LLA-5169	DTP01022	5	Circular
LLA-3170	DTP01023	3	PVC
LLA-5170	DTP01023	5	Circular
TAZ-4290	DTP01024	4	Magica
TAZ-4291	DTP01025	4	Magica
LLA-3171	DTP01026	3	PVC
LLA-5171	DTP01026	5	Rectangular
GOR-2565	DTP01027	2	Blanco
TAZ-4292	DTP01028	4	Normal
TAZ-4293	DTP01029	4	Normal
GOR-2566	DTP01030	2	Azul
TAZ-4294	DTP01031	4	Normal
CAM-1220	DTP01032	1	L
CAM-2567	DTP01032	2	Morado
GOR-2568	DTP01033	2	Blanco
GOR-2569	DTP01034	2	Morado
GOR-2570	DTP01035	2	Rosado
LLA-3172	DTP01036	3	Madera
LLA-5172	DTP01036	5	Circular
LLA-3173	DTP01037	3	PVC
LLA-5173	DTP01037	5	Corazon
CAM-1221	DTP01038	1	S
CAM-2571	DTP01038	2	Rosado
TAZ-4295	DTP01039	4	Normal
GOR-2572	DTP01040	2	Verde
LLA-3174	DTP01041	3	Madera
LLA-5174	DTP01041	5	Circular
GOR-2573	DTP01042	2	Azul
GOR-2574	DTP01043	2	Verde
TAZ-4296	DTP01044	4	Magica
GOR-2575	DTP01045	2	Negro
LLA-3175	DTP01046	3	Madera
LLA-5175	DTP01046	5	Corazon
TER-2576	DTP01047	2	Azul
TER-6049	DTP01047	6	Aluminio
GOR-2577	DTP01048	2	Blanco
TAZ-4297	DTP01049	4	Normal
CAM-1222	DTP01050	1	S
CAM-2578	DTP01050	2	Rojo
CAM-1223	DTP01051	1	S
CAM-2579	DTP01051	2	Azul
GOR-2580	DTP01052	2	Azul
TAZ-4298	DTP01053	4	Magica
CAM-1224	DTP01054	1	12
CAM-2581	DTP01054	2	Negro
GOR-2582	DTP01055	2	Morado
TAZ-4299	DTP01056	4	Normal
CAM-1225	DTP01057	1	12
CAM-2583	DTP01057	2	Blanco
GOR-2584	DTP01058	2	Amarillo
TAZ-4300	DTP01059	4	Magica
GOR-2585	DTP01060	2	Amarillo
TER-2586	DTP01061	2	Rosado
TER-6050	DTP01061	6	Aluminio
TAZ-4301	DTP01062	4	Magica
GOR-2587	DTP01063	2	Rojo
GOR-2588	DTP01064	2	Rosado
LLA-3176	DTP01065	3	Metal
LLA-5176	DTP01065	5	Corazon
CAM-1226	DTP01066	1	14
CAM-2589	DTP01066	2	Amarillo
TAZ-4302	DTP01067	4	Normal
LLA-3177	DTP01068	3	PVC
LLA-5177	DTP01068	5	Corazon
CAM-1227	DTP01069	1	S
CAM-2590	DTP01069	2	Rosado
GOR-2591	DTP01070	2	Amarillo
CAM-1228	DTP01071	1	XXL
CAM-2592	DTP01071	2	Azul
GOR-2593	DTP01072	2	Gris
GOR-2594	DTP01073	2	Amarillo
LLA-3178	DTP01074	3	Madera
LLA-5178	DTP01074	5	Corazon
GOR-2595	DTP01075	2	Gris
GOR-2596	DTP01076	2	Morado
GOR-2597	DTP01077	2	Azul
CAM-1229	DTP01078	1	4
CAM-2598	DTP01078	2	Azul
TER-2599	DTP01079	2	Blanco
TER-6051	DTP01079	6	Plastico
TAZ-4303	DTP01080	4	Magica
TER-2600	DTP01081	2	Morado
TER-6052	DTP01081	6	Plastico
CAM-1230	DTP01082	1	12
CAM-2601	DTP01082	2	Rojo
GOR-2602	DTP01083	2	Blanco
LLA-3179	DTP01084	3	Madera
LLA-5179	DTP01084	5	Circular
LLA-3180	DTP01085	3	Madera
LLA-5180	DTP01085	5	Circular
CAM-1231	DTP01086	1	S
CAM-2603	DTP01086	2	Azul
GOR-2604	DTP01087	2	Azul
TAZ-4304	DTP01088	4	Normal
TAZ-4305	DTP01089	4	Magica
CAM-1232	DTP01090	1	S
CAM-2605	DTP01090	2	Rojo
LLA-3181	DTP01091	3	Metal
LLA-5181	DTP01091	5	Rectangular
LLA-3182	DTP01092	3	Metal
LLA-5182	DTP01092	5	Corazon
LLA-3183	DTP01093	3	Madera
LLA-5183	DTP01093	5	Rectangular
TAZ-4306	DTP01094	4	Magica
TAZ-4307	DTP01095	4	Normal
CAM-1233	DTP01096	1	XXL
CAM-2606	DTP01096	2	Verde
TAZ-4308	DTP01097	4	Magica
GOR-2607	DTP01098	2	Morado
TAZ-4309	DTP01099	4	Magica
TAZ-4310	DTP01100	4	Normal
TAZ-4311	DTP01101	4	Magica
GOR-2608	DTP01102	2	Rosado
TER-2609	DTP01103	2	Rosado
TER-6053	DTP01103	6	Aluminio
CAM-1234	DTP01104	1	6
CAM-2610	DTP01104	2	Azul
TAZ-4312	DTP01105	4	Magica
CAM-1235	DTP01106	1	12
CAM-2611	DTP01106	2	Negro
GOR-2612	DTP01107	2	Verde
CAM-1236	DTP01108	1	M
CAM-2613	DTP01108	2	Azul
GOR-2614	DTP01109	2	Gris
LLA-3184	DTP01110	3	Metal
LLA-5184	DTP01110	5	Rectangular
LLA-3185	DTP01111	3	Metal
LLA-5185	DTP01111	5	Corazon
GOR-2615	DTP01112	2	Rosado
GOR-2616	DTP01113	2	Negro
CAM-1237	DTP01114	1	14
CAM-2617	DTP01114	2	Morado
TAZ-4313	DTP01115	4	Normal
GOR-2618	DTP01116	2	Amarillo
LLA-3186	DTP01117	3	Metal
LLA-5186	DTP01117	5	Circular
GOR-2619	DTP01118	2	Morado
LLA-3187	DTP01119	3	PVC
LLA-5187	DTP01119	5	Rectangular
GOR-2620	DTP01120	2	Verde
CAM-1238	DTP01121	1	12
CAM-2621	DTP01121	2	Blanco
CAM-1239	DTP01122	1	12
CAM-2622	DTP01122	2	Azul
CAM-1240	DTP01123	1	XL
CAM-2623	DTP01123	2	Gris
TAZ-4314	DTP01124	4	Normal
CAM-1241	DTP01125	1	12
CAM-2624	DTP01125	2	Verde
GOR-2625	DTP01126	2	Blanco
TAZ-4315	DTP01127	4	Normal
GOR-2626	DTP01128	2	Rojo
TAZ-4316	DTP01129	4	Normal
CAM-1242	DTP01130	1	L
CAM-2627	DTP01130	2	Negro
TAZ-4317	DTP01131	4	Normal
CAM-1243	DTP01132	1	S
CAM-2628	DTP01132	2	Negro
TER-2629	DTP01133	2	Azul
TER-6054	DTP01133	6	Aluminio
LLA-3188	DTP01134	3	Madera
LLA-5188	DTP01134	5	Circular
LLA-3189	DTP01135	3	Metal
LLA-5189	DTP01135	5	Circular
LLA-3190	DTP01136	3	Metal
LLA-5190	DTP01136	5	Corazon
CAM-1244	DTP01137	1	S
CAM-2630	DTP01137	2	Verde
GOR-2631	DTP01138	2	Amarillo
GOR-2632	DTP01139	2	Rojo
TAZ-4318	DTP01140	4	Normal
GOR-2633	DTP01141	2	Negro
LLA-3191	DTP01142	3	PVC
LLA-5191	DTP01142	5	Rectangular
LLA-3192	DTP01143	3	PVC
LLA-5192	DTP01143	5	Rectangular
GOR-2634	DTP01144	2	Azul
CAM-1245	DTP01145	1	8
CAM-2635	DTP01145	2	Verde
TAZ-4319	DTP01146	4	Magica
LLA-3193	DTP01147	3	Metal
LLA-5193	DTP01147	5	Corazon
CAM-1246	DTP01148	1	XL
CAM-2636	DTP01148	2	Gris
TER-2637	DTP01149	2	Amarillo
TER-6055	DTP01149	6	Plastico
GOR-2638	DTP01150	2	Blanco
TAZ-4320	DTP01151	4	Normal
CAM-1247	DTP01152	1	6
CAM-2639	DTP01152	2	Morado
LLA-3194	DTP01153	3	Metal
LLA-5194	DTP01153	5	Rectangular
LLA-3195	DTP01154	3	PVC
LLA-5195	DTP01154	5	Corazon
TER-2640	DTP01155	2	Negro
TER-6056	DTP01155	6	Aluminio
GOR-2641	DTP01156	2	Blanco
GOR-2642	DTP01157	2	Gris
CAM-1248	DTP01158	1	XXL
CAM-2643	DTP01158	2	Azul
LLA-3196	DTP01159	3	Metal
LLA-5196	DTP01159	5	Circular
GOR-2644	DTP01160	2	Rosado
GOR-2645	DTP01161	2	Amarillo
TAZ-4321	DTP01162	4	Magica
GOR-2646	DTP01163	2	Morado
LLA-3197	DTP01164	3	PVC
LLA-5197	DTP01164	5	Circular
CAM-1249	DTP01165	1	4
CAM-2647	DTP01165	2	Gris
TAZ-4322	DTP01166	4	Normal
CAM-1250	DTP01167	1	6
CAM-2648	DTP01167	2	Morado
CAM-1251	DTP01168	1	6
CAM-2649	DTP01168	2	Rojo
GOR-2650	DTP01169	2	Blanco
CAM-1252	DTP01170	1	14
CAM-2651	DTP01170	2	Verde
TAZ-4323	DTP01171	4	Magica
GOR-2652	DTP01172	2	Azul
LLA-3198	DTP01173	3	Madera
LLA-5198	DTP01173	5	Corazon
TAZ-4324	DTP01174	4	Magica
TER-2653	DTP01175	2	Morado
TER-6057	DTP01175	6	Plastico
CAM-1253	DTP01176	1	S
CAM-2654	DTP01176	2	Negro
GOR-2655	DTP01177	2	Verde
LLA-3199	DTP01178	3	Metal
LLA-5199	DTP01178	5	Circular
TAZ-4325	DTP01179	4	Magica
TER-2656	DTP01180	2	Rosado
TER-6058	DTP01180	6	Plastico
TAZ-4326	DTP01181	4	Magica
TAZ-4327	DTP01182	4	Normal
CAM-1254	DTP01183	1	L
CAM-2657	DTP01183	2	Amarillo
GOR-2658	DTP01184	2	Verde
TAZ-4328	DTP01185	4	Normal
TAZ-4329	DTP01186	4	Magica
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pedidos (pedido_id, cliente_id, usuario_id, notas, estado_id, total, fecha_creacion, fecha_modificacion, fecha_finalizacion, fecha_estimada_entrega, metodo_id, hora_estimada_entrega) FROM stdin;
250101-PDD004	CL066	R001	\N	5	200.00	2025-01-01 12:00:00	2025-01-02 00:00:00	2025-01-02 13:00:00	2025-01-02 10:00:00	4	16:15:00
250101-PDD006	CL305	R002	\N	3	700.00	2025-01-01 15:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	3	12:45:00
250101-PDD002	CL022	R001	Cliente quiere ver 2 diseños preliminares	5	1300.00	2025-01-01 10:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	1	16:45:00
250101-PDD003	CL226	R001	Cliente quiere ver 2 diseños preliminares	5	1200.00	2025-01-01 11:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	2	13:15:00
250101-PDD005	CL003	R001	\N	5	100.00	2025-01-01 14:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	3	15:30:00
250101-PDD007	CL298	R001	El cliente pidió prioridad de entrega	5	1110.00	2025-01-01 16:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	2025-01-02 00:00:00	4	13:45:00
250102-PDD008	CL300	R002	\N	5	440.00	2025-01-02 10:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	1	08:45:00
250103-PDD017	CL176	R001	\N	1	1200.00	2025-01-03 14:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	2	10:30:00
250102-PDD009	CL128	R002	\N	5	1000.00	2025-01-02 11:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	1	15:30:00
250103-PDD016	CL156	R001	El cliente pidió prioridad de entrega	5	1200.00	2025-01-03 12:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	3	13:00:00
250103-PDD018	CL220	R002	\N	5	550.00	2025-01-03 15:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	3	10:15:00
250103-PDD019	CL041	R001	\N	5	550.00	2025-01-03 16:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	4	16:30:00
250104-PDD020	CL269	R002	\N	5	900.00	2025-01-04 10:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	3	11:15:00
250104-PDD021	CL054	R001	\N	5	1250.00	2025-01-04 11:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	3	08:45:00
250104-PDD022	CL071	R001	\N	5	1400.00	2025-01-04 12:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	2	15:30:00
250103-PDD015	CL132	R001	El cliente no estuvo contento con el acabado de las gorras y no quiso aceptar un nuevo diseño, se reembolso el dinero.	6	720.00	2025-01-03 11:00:00	2025-01-04 00:00:00	2025-01-04 15:00:00	2025-01-04 14:00:00	2	14:15:00
250104-PDD023	CL121	R001	El cliente pidió prioridad de entrega	5	1210.00	2025-01-04 14:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	4	11:15:00
250104-PDD024	CL307	R001	\N	5	300.00	2025-01-04 15:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	4	16:15:00
250104-PDD025	CL180	R001	\N	5	600.00	2025-01-04 16:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	2025-01-05 00:00:00	4	10:15:00
250105-PDD026	CL233	R001	\N	5	400.00	2025-01-05 10:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	3	08:45:00
250105-PDD027	CL122	R001	\N	5	1510.00	2025-01-05 11:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	3	12:15:00
250105-PDD028	CL108	R001	\N	5	850.00	2025-01-05 12:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	1	16:00:00
250105-PDD029	CL080	R001	\N	5	800.00	2025-01-05 14:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	2	10:45:00
250105-PDD030	CL206	R001	\N	5	300.00	2025-01-05 15:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	4	13:30:00
250105-PDD031	CL030	R001	\N	5	1200.00	2025-01-05 16:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	2025-01-06 00:00:00	1	09:00:00
250106-PDD032	CL092	R001	\N	5	600.00	2025-01-06 10:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	1	10:15:00
250106-PDD033	CL094	R001	\N	5	1200.00	2025-01-06 11:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	4	08:00:00
250106-PDD034	CL245	R001	\N	5	1200.00	2025-01-06 12:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	4	14:45:00
250106-PDD035	CL150	R001	\N	5	450.00	2025-01-06 14:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	3	16:00:00
250106-PDD036	CL304	R001	\N	5	600.00	2025-01-06 15:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	1	09:15:00
250106-PDD037	CL139	R001	\N	5	510.00	2025-01-06 16:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	2025-01-07 00:00:00	2	08:45:00
250107-PDD038	CL125	R001	\N	5	800.00	2025-01-07 10:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	2	13:45:00
250107-PDD039	CL187	R001	\N	5	1200.00	2025-01-07 11:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	4	15:15:00
250107-PDD040	CL179	R001	\N	5	1200.00	2025-01-07 12:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	4	13:45:00
250113-PDD079	CL243	R001	\N	5	980.00	2025-01-13 16:00:00	2025-01-14 00:00:00	2025-01-14 00:00:00	2025-01-14 00:00:00	3	13:15:00
250114-PDD080	CL183	R002	\N	5	450.00	2025-01-14 10:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	1	16:15:00
250114-PDD082	CL117	R001	\N	5	1400.00	2025-01-14 12:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	1	09:15:00
250107-PDD041	CL249	R001	\N	5	450.00	2025-01-07 14:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	1	12:15:00
250107-PDD042	CL088	R001	\N	5	150.00	2025-01-07 15:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	1	08:45:00
250108-PDD047	CL116	R001	Pedido urgente para cliente regular	5	2280.00	2025-01-08 14:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	1	11:00:00
250108-PDD048	CL165	R002	El cliente pidió prioridad de entrega	5	450.00	2025-01-08 15:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	4	14:15:00
250109-PDD050	CL191	R002	Pedido urgente para cliente regular	5	1310.00	2025-01-09 10:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	3	11:00:00
250109-PDD051	CL153	R001	El cliente pidió prioridad de entrega	5	1050.00	2025-01-09 11:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	2	13:15:00
250108-PDD049	CL128	R002	\N	5	900.00	2025-01-08 16:00:00	2025-01-09 00:00:00	2025-01-09 13:10:00	2025-01-09 12:00:00	2	11:00:00
250109-PDD052	CL307	R002	\N	5	800.00	2025-01-09 12:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	4	09:15:00
250109-PDD053	CL304	R002	Pedido urgente para cliente regular	5	550.00	2025-01-09 14:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	1	09:15:00
250109-PDD054	CL295	R002	\N	5	300.00	2025-01-09 15:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	4	12:15:00
250109-PDD055	CL273	R001	\N	5	900.00	2025-01-09 16:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	2025-01-10 00:00:00	1	09:00:00
250110-PDD056	CL255	R001	\N	5	1970.00	2025-01-10 10:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	3	10:00:00
250110-PDD057	CL064	R002	\N	5	600.00	2025-01-10 11:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	3	11:30:00
250110-PDD058	CL289	R001	\N	5	1100.00	2025-01-10 12:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	2	08:00:00
250110-PDD060	CL064	R002	\N	5	200.00	2025-01-10 15:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	3	15:15:00
250114-PDD083	CL100	R001	Pedido urgente para cliente regular	5	300.00	2025-01-14 14:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	4	10:00:00
250110-PDD059	CL207	R001	Usar diseño minimalista para este pedido	5	930.00	2025-01-10 14:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	3	16:45:00
250110-PDD061	CL150	R002	\N	5	450.00	2025-01-10 16:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	2025-01-11 00:00:00	4	14:15:00
250111-PDD062	CL150	R002	\N	5	900.00	2025-01-11 10:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2	08:45:00
250111-PDD063	CL012	R001	Usar diseño minimalista para este pedido	5	1100.00	2025-01-11 11:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2	08:15:00
250111-PDD064	CL023	R002	\N	5	1200.00	2025-01-11 12:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	1	12:30:00
250111-PDD065	CL051	R002	\N	5	400.00	2025-01-11 14:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	4	10:15:00
250111-PDD066	CL084	R001	\N	5	1600.00	2025-01-11 15:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2	13:30:00
250111-PDD067	CL114	R001	Cliente quiere ver 2 diseños preliminares	5	800.00	2025-01-11 16:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	2025-01-12 00:00:00	3	15:45:00
250112-PDD068	CL048	R002	\N	5	1200.00	2025-01-12 10:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	4	16:30:00
250112-PDD069	CL050	R001	\N	5	500.00	2025-01-12 11:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	3	12:30:00
250112-PDD070	CL309	R001	Cliente quiere ver 2 diseños preliminares	5	2000.00	2025-01-12 12:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	2	14:00:00
250112-PDD071	CL127	R002	\N	5	600.00	2025-01-12 14:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	3	15:00:00
250112-PDD072	CL222	R001	Pedido urgente para cliente regular	5	900.00	2025-01-12 15:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	1	13:15:00
250114-PDD081	CL291	R001	Cliente quiere ver 2 diseños preliminares	5	1520.00	2025-01-14 11:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	2	12:00:00
250114-PDD084	CL125	R002	\N	5	1050.00	2025-01-14 15:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	4	12:45:00
250114-PDD085	CL221	R002	\N	5	1050.00	2025-01-14 16:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	2025-01-15 00:00:00	2	10:45:00
250115-PDD086	CL268	R001	Cliente quiere ver 2 diseños preliminares	5	1160.00	2025-01-15 10:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	4	10:30:00
250115-PDD087	CL248	R002	\N	5	150.00	2025-01-15 11:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	3	12:45:00
250115-PDD088	CL037	R002	\N	5	450.00	2025-01-15 12:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2	08:30:00
250115-PDD089	CL055	R002	\N	5	600.00	2025-01-15 14:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	1	12:15:00
250115-PDD090	CL002	R002	\N	5	300.00	2025-01-15 15:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2	14:15:00
250115-PDD091	CL169	R002	\N	5	600.00	2025-01-15 16:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2025-01-16 00:00:00	2	12:45:00
250116-PDD094	CL023	R002	Cliente rechazo por desperfecto en la taza, se orefecio reemplaszar y el cliente acepto.	6	150.00	2025-01-16 12:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	2	16:15:00
250116-PDD092	CL056	R002	\N	5	1200.00	2025-01-16 10:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	1	16:45:00
250116-PDD093	CL077	R002	\N	5	900.00	2025-01-16 11:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	2	13:30:00
250116-PDD095	CL067	R002	\N	5	450.00	2025-01-16 14:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	2	16:15:00
250116-PDD096	CL010	R001	\N	5	1550.00	2025-01-16 15:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	2025-01-17 00:00:00	4	16:00:00
250117-PDD098	CL254	R002	\N	5	1070.00	2025-01-17 10:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	3	13:30:00
250117-PDD099	CL257	R001	Pedido urgente para cliente regular	5	1550.00	2025-01-17 11:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	3	15:00:00
250117-PDD100	CL101	R002	\N	5	450.00	2025-01-17 12:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	1	14:30:00
250116-PDD097	CL293	R001	\N	5	200.00	2025-01-16 16:00:00	2025-01-17 00:00:00	2025-01-17 13:50:00	2025-01-17 12:30:00	3	09:00:00
250117-PDD101	CL014	R002	\N	5	600.00	2025-01-17 14:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	1	14:15:00
250117-PDD103	CL267	R001	\N	5	600.00	2025-01-17 16:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	2025-01-18 00:00:00	4	08:15:00
250118-PDD104	CL264	R002	\N	5	950.00	2025-01-18 10:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	3	10:45:00
250118-PDD105	CL138	R002	\N	5	600.00	2025-01-18 11:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	1	15:15:00
250119-PDD114	CL264	R001	\N	5	400.00	2025-01-19 15:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	2	09:45:00
250119-PDD115	CL217	R001	\N	5	1100.00	2025-01-19 16:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	3	10:15:00
250120-PDD116	CL295	R002	\N	5	1200.00	2025-01-20 10:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	2	10:45:00
250120-PDD117	CL217	R001	Pedido urgente para cliente regular	5	170.00	2025-01-20 11:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	3	15:15:00
250120-PDD118	CL152	R002	\N	5	2360.00	2025-01-20 12:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	1	08:30:00
250118-PDD106	CL151	R002	El cliente no estuvo contento con la fecha de entrega, se ofrecio descuento del 50%	6	750.00	2025-01-18 12:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	1	12:45:00
250120-PDD119	CL139	R001	\N	5	450.00	2025-01-20 14:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	1	15:30:00
250120-PDD121	CL168	R002	\N	5	920.00	2025-01-20 16:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	2025-01-21 00:00:00	3	14:30:00
250121-PDD122	CL276	R001	\N	5	700.00	2025-01-21 10:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	3	15:15:00
250121-PDD123	CL303	R002	Pedido urgente para cliente regular	5	550.00	2025-01-21 11:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	3	08:15:00
250121-PDD124	CL212	R001	\N	5	800.00	2025-01-21 12:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	2	16:00:00
250120-PDD120	CL268	R002	Pedido urgente para cliente regular	5	600.00	2025-01-20 15:00:00	2025-01-21 00:00:00	2025-01-21 15:10:00	2025-01-21 15:00:00	1	14:15:00
250117-PDD102	CL261	R002	\N	5	600.00	2025-01-17 15:00:00	2025-01-18 00:00:00	2025-01-18 15:50:00	2025-01-18 14:30:00	4	11:15:00
250121-PDD125	CL159	R002	\N	5	830.00	2025-01-21 14:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	4	15:30:00
250121-PDD126	CL275	R002	\N	5	1470.00	2025-01-21 15:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	3	11:15:00
250121-PDD127	CL132	R001	\N	5	150.00	2025-01-21 16:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	2025-01-22 00:00:00	1	12:45:00
250122-PDD128	CL129	R001	Usar diseño minimalista para este pedido	5	930.00	2025-01-22 10:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	1	10:30:00
250122-PDD129	CL037	R002	Cliente quiere ver 2 diseños preliminares	5	750.00	2025-01-22 11:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	4	13:45:00
250122-PDD130	CL053	R001	\N	5	700.00	2025-01-22 12:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	2	14:45:00
250123-PDD137	CL096	R002	Cliente no quizo pedido, se ofrecio reembolso y no acepto	6	550.00	2025-01-23 14:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	1	13:15:00
250122-PDD131	CL216	R002	\N	5	450.00	2025-01-22 14:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	3	15:45:00
250122-PDD132	CL308	R001	\N	5	450.00	2025-01-22 15:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	4	15:15:00
250122-PDD133	CL152	R002	\N	5	1050.00	2025-01-22 16:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	2025-01-23 00:00:00	4	08:15:00
250124-PDD140	CL048	R001	El cliente pidió prioridad de entrega	5	950.00	2025-01-24 10:00:00	2025-01-25 00:00:00	2025-01-25 13:10:00	2025-01-25 12:30:00	4	08:00:00
250123-PDD134	CL010	R002	\N	5	1550.00	2025-01-23 10:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	3	12:30:00
250123-PDD135	CL116	R001	\N	5	800.00	2025-01-23 11:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	2	08:30:00
250123-PDD136	CL060	R002	\N	5	600.00	2025-01-23 12:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	1	16:30:00
250123-PDD138	CL054	R001	Pedido urgente para cliente regular	5	570.00	2025-01-23 15:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	3	11:30:00
250123-PDD139	CL141	R001	Usar diseño minimalista para este pedido	5	450.00	2025-01-23 16:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	2025-01-24 00:00:00	2	13:45:00
250125-PDD147	CL233	R001	\N	5	450.00	2025-01-25 11:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	1	14:45:00
250125-PDD148	CL135	R001	\N	5	1000.00	2025-01-25 12:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	4	10:00:00
250125-PDD149	CL012	R001	Usar diseño minimalista para este pedido	5	980.00	2025-01-25 14:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	2	09:15:00
250125-PDD150	CL189	R002	\N	5	600.00	2025-01-25 15:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	1	12:00:00
250126-PDD152	CL028	R002	\N	5	780.00	2025-01-26 10:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	4	11:45:00
250126-PDD153	CL264	R001	Cliente quiere ver 2 diseños preliminares	5	1050.00	2025-01-26 11:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2	09:30:00
250126-PDD154	CL286	R002	\N	5	1100.00	2025-01-26 12:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	3	11:45:00
250126-PDD155	CL146	R002	\N	5	1250.00	2025-01-26 14:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	3	08:00:00
250126-PDD156	CL284	R001	Cliente quiere ver 2 diseños preliminares	5	1050.00	2025-01-26 15:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2	14:15:00
250126-PDD157	CL230	R002	El cliente pidió prioridad de entrega	5	850.00	2025-01-26 16:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2025-01-27 00:00:00	2	16:00:00
250127-PDD158	CL125	R002	\N	5	1450.00	2025-01-27 10:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	3	10:45:00
250127-PDD159	CL162	R001	\N	5	1650.00	2025-01-27 11:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	3	08:00:00
250127-PDD160	CL143	R001	\N	5	1000.00	2025-01-27 12:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	3	09:30:00
250127-PDD161	CL130	R002	Pedido urgente para cliente regular	5	150.00	2025-01-27 14:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	1	10:45:00
250127-PDD162	CL150	R002	\N	5	1050.00	2025-01-27 15:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	1	14:45:00
250102-PDD010	CL058	R001	Usar diseño minimalista para este pedido	5	1000.00	2025-01-02 12:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	3	09:45:00
250102-PDD011	CL297	R001	\N	5	1170.00	2025-01-02 14:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	2	09:30:00
250102-PDD012	CL210	R001	\N	5	450.00	2025-01-02 15:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	3	10:15:00
250102-PDD013	CL008	R001	\N	5	1200.00	2025-01-02 16:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	2025-01-03 00:00:00	1	13:00:00
250103-PDD014	CL066	R002	\N	5	1390.00	2025-01-03 10:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	2025-01-04 00:00:00	3	08:15:00
250127-PDD163	CL286	R001	\N	5	450.00	2025-01-27 16:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	2025-01-28 00:00:00	1	09:00:00
250128-PDD164	CL202	R002	Cliente quiere ver 2 diseños preliminares	5	450.00	2025-01-28 10:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	3	08:45:00
250128-PDD165	CL088	R002	\N	5	1200.00	2025-01-28 11:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	3	10:15:00
250128-PDD166	CL009	R002	\N	5	1490.00	2025-01-28 12:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	3	14:15:00
250128-PDD167	CL149	R002	\N	5	850.00	2025-01-28 14:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	2	15:15:00
250128-PDD168	CL240	R002	\N	5	600.00	2025-01-28 15:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	4	09:00:00
250128-PDD169	CL281	R001	\N	5	600.00	2025-01-28 16:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	2025-01-29 00:00:00	1	16:30:00
250129-PDD170	CL245	R002	Usar diseño minimalista para este pedido	5	1850.00	2025-01-29 10:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	2	15:45:00
250130-PDD177	CL057	R002	\N	5	950.00	2025-01-30 11:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	3	08:30:00
250130-PDD178	CL046	R001	\N	5	1050.00	2025-01-30 12:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	2	12:45:00
250130-PDD179	CL193	R001	\N	5	850.00	2025-01-30 14:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	4	09:15:00
250130-PDD180	CL240	R001	\N	5	800.00	2025-01-30 15:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	1	12:30:00
250107-PDD043	CL217	R002	\N	5	770.00	2025-01-07 16:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	2025-01-08 00:00:00	1	14:30:00
250108-PDD044	CL249	R002	\N	5	900.00	2025-01-08 10:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	4	16:00:00
250108-PDD045	CL205	R001	\N	5	500.00	2025-01-08 11:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	3	16:30:00
250108-PDD046	CL259	R001	Cliente quiere ver 2 diseños preliminares	5	450.00	2025-01-08 12:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	2025-01-09 00:00:00	2	16:45:00
250130-PDD181	CL057	R002	\N	5	1400.00	2025-01-30 16:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	4	16:30:00
250131-PDD182	CL074	R001	\N	5	1050.00	2025-01-31 10:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	4	14:00:00
250131-PDD183	CL274	R002	Usar diseño minimalista para este pedido	5	320.00	2025-01-31 11:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	3	10:15:00
250131-PDD184	CL196	R002	\N	5	1140.00	2025-01-31 12:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	4	11:15:00
250131-PDD185	CL087	R001	\N	5	840.00	2025-01-31 14:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	2	11:45:00
250131-PDD186	CL203	R001	El cliente pidió prioridad de entrega	5	450.00	2025-01-31 15:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	3	14:30:00
250131-PDD187	CL293	R002	\N	5	570.00	2025-01-31 16:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	2025-02-01 00:00:00	2	15:45:00
250201-PDD188	CL298	R002	Usar diseño minimalista para este pedido	5	600.00	2025-02-01 10:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	3	16:45:00
250201-PDD189	CL052	R002	El cliente pidió prioridad de entrega	5	600.00	2025-02-01 11:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	4	14:45:00
250201-PDD190	CL024	R001	\N	5	550.00	2025-02-01 12:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	2	14:00:00
250201-PDD191	CL102	R002	\N	5	150.00	2025-02-01 14:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	2	16:00:00
250112-PDD073	CL078	R001	\N	5	700.00	2025-01-12 16:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	2025-01-13 00:00:00	1	11:45:00
250113-PDD074	CL095	R002	\N	5	300.00	2025-01-13 10:00:00	2025-01-14 00:00:00	2025-01-14 00:00:00	2025-01-14 00:00:00	3	08:00:00
250113-PDD075	CL013	R002	\N	5	750.00	2025-01-13 11:00:00	2025-01-14 00:00:00	2025-01-14 00:00:00	2025-01-14 00:00:00	3	16:15:00
250113-PDD076	CL221	R001	Cliente quiere ver 2 diseños preliminares	5	1050.00	2025-01-13 12:00:00	2025-01-14 00:00:00	2025-01-14 00:00:00	2025-01-14 00:00:00	4	13:30:00
250203-PDD200	CL103	R001	\N	5	480.00	2025-02-03 10:00:00	2025-02-04 00:00:00	2025-02-04 14:45:00	2025-02-04 12:00:00	2	09:15:00
250201-PDD192	CL097	R002	\N	5	1000.00	2025-02-01 15:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	1	09:30:00
250201-PDD193	CL107	R002	\N	5	450.00	2025-02-01 16:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	2025-02-02 00:00:00	4	15:15:00
250202-PDD194	CL142	R001	\N	5	600.00	2025-02-02 10:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2	16:15:00
250202-PDD195	CL010	R002	\N	5	1000.00	2025-02-02 11:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2	08:30:00
250202-PDD196	CL060	R002	\N	5	300.00	2025-02-02 12:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2	15:15:00
250202-PDD197	CL190	R001	\N	5	1000.00	2025-02-02 14:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	4	11:15:00
250202-PDD198	CL286	R002	Usar diseño minimalista para este pedido	5	200.00	2025-02-02 15:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	1	11:45:00
250202-PDD199	CL252	R001	\N	5	550.00	2025-02-02 16:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	2025-02-03 00:00:00	4	14:15:00
250203-PDD201	CL146	R002	\N	5	1260.00	2025-02-03 11:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	1	12:15:00
250203-PDD202	CL177	R002	\N	5	600.00	2025-02-03 12:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	3	09:45:00
250113-PDD077	CL162	R001	\N	5	510.00	2025-01-13 14:00:00	2025-01-14 00:00:00	2025-01-14 13:50:00	2025-01-14 13:30:00	1	11:15:00
250118-PDD107	CL301	R002	\N	5	400.00	2025-01-18 14:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	3	16:45:00
250118-PDD108	CL224	R002	\N	5	1400.00	2025-01-18 15:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	4	13:30:00
250118-PDD109	CL201	R002	\N	5	450.00	2025-01-18 16:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	2025-01-19 00:00:00	1	08:00:00
250119-PDD110	CL254	R001	Usar diseño minimalista para este pedido	5	700.00	2025-01-19 10:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	4	16:00:00
250119-PDD111	CL153	R002	\N	5	200.00	2025-01-19 11:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	4	12:30:00
250119-PDD112	CL012	R002	Usar diseño minimalista para este pedido	5	2050.00	2025-01-19 12:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	3	10:45:00
250119-PDD113	CL097	R002	\N	5	600.00	2025-01-19 14:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	2025-01-20 00:00:00	1	15:45:00
250203-PDD203	CL158	R001	\N	5	450.00	2025-02-03 14:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	4	12:45:00
250203-PDD204	CL089	R001	\N	5	550.00	2025-02-03 15:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	4	14:30:00
250203-PDD205	CL302	R001	\N	5	910.00	2025-02-03 16:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	2025-02-04 00:00:00	4	15:15:00
250205-PDD215	CL017	R002	El cliente pidió prioridad de entrega	5	1000.00	2025-02-05 14:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	3	08:30:00
250205-PDD216	CL185	R002	Pedido urgente para cliente regular	5	900.00	2025-02-05 15:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	2	09:30:00
250205-PDD217	CL273	R002	Pedido urgente para cliente regular	5	750.00	2025-02-05 16:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	1	14:00:00
250124-PDD141	CL084	R002	\N	5	1220.00	2025-01-24 11:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	4	15:00:00
250124-PDD142	CL004	R002	\N	5	150.00	2025-01-24 12:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	1	08:00:00
250124-PDD143	CL122	R002	Pedido urgente para cliente regular	5	800.00	2025-01-24 14:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	4	16:45:00
250124-PDD144	CL198	R001	\N	5	450.00	2025-01-24 15:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	4	15:15:00
250124-PDD145	CL299	R002	\N	5	1630.00	2025-01-24 16:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	2025-01-25 00:00:00	1	10:30:00
250125-PDD146	CL206	R002	\N	5	1850.00	2025-01-25 10:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	3	12:00:00
250125-PDD151	CL127	R002	Pedido urgente para cliente regular	5	750.00	2025-01-25 16:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	2025-01-26 00:00:00	3	14:45:00
250129-PDD171	CL231	R001	\N	5	1350.00	2025-01-29 11:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	3	09:30:00
250129-PDD173	CL296	R002	\N	5	1160.00	2025-01-29 14:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	3	09:30:00
250129-PDD174	CL208	R001	\N	5	1150.00	2025-01-29 15:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	4	15:15:00
250129-PDD175	CL131	R002	\N	5	900.00	2025-01-29 16:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	2025-01-30 00:00:00	3	14:30:00
250130-PDD176	CL177	R001	Cliente quiere ver 2 diseños preliminares	5	600.00	2025-01-30 10:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	2025-01-31 00:00:00	4	16:15:00
250129-PDD172	CL116	R001	\N	5	750.00	2025-01-29 12:00:00	2025-01-30 00:00:00	2025-01-31 10:00:00	2025-01-30 16:00:00	1	14:00:00
250204-PDD206	CL137	R001	\N	5	1050.00	2025-02-04 10:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	4	10:30:00
250204-PDD207	CL307	R002	\N	5	600.00	2025-02-04 11:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	4	09:30:00
250204-PDD209	CL016	R001	\N	5	1600.00	2025-02-04 14:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	3	08:45:00
250204-PDD210	CL181	R001	\N	5	170.00	2025-02-04 15:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	4	11:30:00
250204-PDD211	CL065	R001	Usar diseño minimalista para este pedido	5	600.00	2025-02-04 16:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	2025-02-05 00:00:00	2	12:15:00
250205-PDD212	CL037	R002	\N	5	1300.00	2025-02-05 10:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	2	10:00:00
250205-PDD213	CL011	R002	\N	5	1400.00	2025-02-05 11:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	1	10:45:00
250205-PDD214	CL299	R001	El cliente pidió prioridad de entrega	5	1500.00	2025-02-05 12:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	2025-02-06 00:00:00	1	12:15:00
250204-PDD208	CL289	R002	\N	5	450.00	2025-02-04 12:00:00	2025-02-05 00:00:00	2025-02-05 11:40:00	2025-02-05 10:00:00	3	12:15:00
250206-PDD218	CL255	R001	El cliente pidió prioridad de entrega	5	1800.00	2025-02-06 10:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	3	12:00:00
250206-PDD219	CL302	R001	\N	5	600.00	2025-02-06 11:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	2	12:30:00
250206-PDD220	CL244	R001	\N	5	700.00	2025-02-06 12:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	4	13:45:00
250206-PDD221	CL298	R001	El cliente pidió prioridad de entrega	5	1100.00	2025-02-06 14:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	3	09:00:00
250206-PDD222	CL060	R001	\N	5	600.00	2025-02-06 15:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	3	11:15:00
250206-PDD223	CL073	R001	Cliente quiere ver 2 diseños preliminares	5	1200.00	2025-02-06 16:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	2025-02-07 00:00:00	2	14:15:00
250207-PDD224	CL020	R001	\N	5	600.00	2025-02-07 10:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	1	15:15:00
250207-PDD225	CL025	R002	\N	5	900.00	2025-02-07 11:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	4	09:45:00
250207-PDD226	CL071	R001	\N	5	450.00	2025-02-07 12:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	3	08:15:00
250207-PDD228	CL235	R001	\N	5	150.00	2025-02-07 15:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	4	08:45:00
250207-PDD229	CL075	R002	\N	5	300.00	2025-02-07 16:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	2025-02-08 00:00:00	2	15:15:00
250208-PDD230	CL086	R001	\N	5	1000.00	2025-02-08 10:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	4	08:30:00
250208-PDD231	CL078	R001	\N	5	400.00	2025-02-08 11:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	4	08:15:00
250208-PDD232	CL036	R002	\N	5	1200.00	2025-02-08 12:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2	10:30:00
250207-PDD227	CL042	R002	\N	5	150.00	2025-02-07 14:00:00	2025-02-08 00:00:00	2025-02-08 11:45:00	2025-02-08 11:30:00	4	15:15:00
250208-PDD233	CL207	R001	\N	5	400.00	2025-02-08 14:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	3	09:00:00
250208-PDD234	CL274	R001	El cliente pidió prioridad de entrega	5	1350.00	2025-02-08 15:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2	08:30:00
250208-PDD235	CL147	R002	\N	5	440.00	2025-02-08 16:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2025-02-09 00:00:00	2	11:15:00
250209-PDD236	CL202	R002	\N	5	1450.00	2025-02-09 10:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2	12:45:00
250209-PDD237	CL283	R001	\N	5	1150.00	2025-02-09 11:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	1	16:15:00
250209-PDD238	CL099	R002	\N	5	1300.00	2025-02-09 12:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	3	15:30:00
250209-PDD239	CL201	R002	\N	5	660.00	2025-02-09 14:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2	09:15:00
250209-PDD240	CL211	R001	\N	5	300.00	2025-02-09 15:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	1	14:45:00
250209-PDD241	CL232	R002	\N	5	680.00	2025-02-09 16:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2025-02-10 00:00:00	2	10:45:00
250210-PDD242	CL006	R001	\N	5	200.00	2025-02-10 10:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2	08:15:00
250210-PDD243	CL054	R002	\N	5	1200.00	2025-02-10 11:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2	16:30:00
250210-PDD244	CL090	R001	\N	5	840.00	2025-02-10 12:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2	08:00:00
250210-PDD245	CL282	R002	\N	5	400.00	2025-02-10 14:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	4	13:15:00
250210-PDD246	CL018	R002	\N	5	1200.00	2025-02-10 15:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	1	15:00:00
250210-PDD247	CL289	R001	\N	5	2200.00	2025-02-10 16:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	2025-02-11 00:00:00	4	14:00:00
250211-PDD248	CL073	R002	\N	5	400.00	2025-02-11 10:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	1	09:45:00
250211-PDD249	CL236	R001	\N	5	800.00	2025-02-11 11:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	3	08:15:00
250211-PDD250	CL252	R001	\N	5	1200.00	2025-02-11 12:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	4	11:00:00
250211-PDD251	CL014	R001	Pedido urgente para cliente regular	5	1350.00	2025-02-11 14:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	3	15:45:00
250211-PDD252	CL290	R001	Cliente quiere ver 2 diseños preliminares	5	1000.00	2025-02-11 15:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	2	09:30:00
250211-PDD253	CL180	R001	\N	5	600.00	2025-02-11 16:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	2025-02-12 00:00:00	2	16:00:00
250212-PDD254	CL060	R002	Usar diseño minimalista para este pedido	5	1520.00	2025-02-12 10:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	1	09:00:00
250212-PDD255	CL003	R002	\N	5	660.00	2025-02-12 11:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2	12:45:00
250212-PDD256	CL066	R002	\N	5	750.00	2025-02-12 12:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	1	11:00:00
250212-PDD257	CL137	R002	\N	5	2200.00	2025-02-12 14:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	1	09:45:00
250212-PDD258	CL166	R001	Cliente quiere ver 2 diseños preliminares	5	710.00	2025-02-12 15:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2	14:45:00
250212-PDD259	CL109	R001	\N	5	800.00	2025-02-12 16:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2025-02-13 00:00:00	2	12:30:00
250213-PDD260	CL145	R002	\N	5	1320.00	2025-02-13 10:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	1	10:15:00
250213-PDD261	CL284	R002	\N	5	1710.00	2025-02-13 11:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	4	15:15:00
250213-PDD262	CL254	R001	Cliente quiere ver 2 diseños preliminares	5	550.00	2025-02-13 12:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	2	13:00:00
250213-PDD263	CL118	R001	\N	5	600.00	2025-02-13 14:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	2	11:00:00
250213-PDD264	CL249	R002	Usar diseño minimalista para este pedido	5	800.00	2025-02-13 15:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	1	16:15:00
250213-PDD265	CL196	R002	\N	5	750.00	2025-02-13 16:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	2025-02-14 00:00:00	4	08:15:00
250214-PDD266	CL235	R002	Pedido urgente para cliente regular	5	850.00	2025-02-14 10:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	1	10:00:00
250214-PDD267	CL163	R001	\N	5	500.00	2025-02-14 11:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	4	14:00:00
250214-PDD268	CL195	R002	Pedido urgente para cliente regular	5	150.00	2025-02-14 12:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	1	08:00:00
250214-PDD269	CL147	R002	\N	5	750.00	2025-02-14 14:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	1	12:15:00
250214-PDD270	CL062	R002	\N	5	900.00	2025-02-14 15:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	2	15:45:00
250214-PDD271	CL039	R001	\N	5	650.00	2025-02-14 16:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	2025-02-15 00:00:00	3	11:30:00
250215-PDD272	CL301	R002	\N	5	1750.00	2025-02-15 10:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	3	08:45:00
250215-PDD273	CL252	R002	\N	5	840.00	2025-02-15 11:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	1	12:00:00
250215-PDD274	CL200	R002	\N	5	400.00	2025-02-15 12:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	2	16:00:00
250215-PDD275	CL031	R002	\N	5	950.00	2025-02-15 14:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	2	13:15:00
250216-PDD281	CL287	R002	Usar diseño minimalista para este pedido	5	1200.00	2025-02-16 14:00:00	2025-02-17 00:00:00	2025-02-17 14:50:00	2025-02-17 14:00:00	2	14:30:00
250215-PDD276	CL136	R001	\N	5	1020.00	2025-02-15 15:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	4	15:15:00
250215-PDD277	CL016	R001	\N	5	1000.00	2025-02-15 16:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	2025-02-16 00:00:00	1	16:00:00
250216-PDD278	CL050	R002	Pedido urgente para cliente regular	5	750.00	2025-02-16 10:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	3	08:15:00
250216-PDD279	CL115	R002	\N	5	1010.00	2025-02-16 11:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	2	16:45:00
250216-PDD280	CL031	R001	\N	5	150.00	2025-02-16 12:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	2	10:45:00
250216-PDD282	CL127	R002	\N	5	1350.00	2025-02-16 15:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	3	15:45:00
250216-PDD283	CL093	R001	\N	5	1150.00	2025-02-16 16:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	2025-02-17 00:00:00	4	15:45:00
250217-PDD284	CL016	R001	\N	5	1440.00	2025-02-17 10:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2	13:00:00
250217-PDD285	CL126	R002	Cliente quiere ver 2 diseños preliminares	5	300.00	2025-02-17 11:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2	16:00:00
250217-PDD286	CL292	R001	\N	5	1100.00	2025-02-17 12:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	3	10:45:00
250217-PDD287	CL148	R002	\N	5	1330.00	2025-02-17 14:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	1	15:00:00
250217-PDD288	CL076	R002	\N	5	350.00	2025-02-17 15:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2	12:15:00
250217-PDD289	CL209	R002	\N	5	1450.00	2025-02-17 16:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	2025-02-18 00:00:00	4	12:00:00
250226-PDD339	CL247	R002	\N	5	360.00	2025-02-26 11:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	4	12:30:00
250218-PDD290	CL054	R001	Pedido urgente para cliente regular	5	1400.00	2025-02-18 10:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	2	16:15:00
250218-PDD291	CL112	R002	\N	5	600.00	2025-02-18 11:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	3	11:15:00
250218-PDD292	CL006	R002	Usar diseño minimalista para este pedido	5	200.00	2025-02-18 12:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	4	11:00:00
250218-PDD293	CL246	R001	\N	5	450.00	2025-02-18 14:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	3	10:30:00
250220-PDD306	CL161	R002	\N	5	1050.00	2025-02-20 15:00:00	2025-02-21 00:00:00	2025-02-21 09:00:00	2025-02-21 08:00:00	1	14:45:00
250218-PDD294	CL225	R002	\N	5	1700.00	2025-02-18 15:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	4	09:30:00
250218-PDD295	CL041	R002	\N	5	1000.00	2025-02-18 16:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	2025-02-19 00:00:00	1	12:00:00
250219-PDD296	CL103	R001	\N	5	600.00	2025-02-19 10:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	4	08:45:00
250219-PDD301	CL128	R001	\N	5	1850.00	2025-02-19 16:00:00	2025-02-20 00:00:00	2025-02-20 15:10:00	2025-02-20 13:00:00	2	15:45:00
250219-PDD297	CL303	R001	\N	5	300.00	2025-02-19 11:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	4	11:30:00
250219-PDD298	CL289	R002	Cliente quiere ver 2 diseños preliminares	5	1850.00	2025-02-19 12:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	1	09:30:00
250219-PDD299	CL025	R002	\N	5	800.00	2025-02-19 14:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	4	11:15:00
250219-PDD300	CL054	R002	\N	5	750.00	2025-02-19 15:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	2025-02-20 00:00:00	3	09:15:00
250220-PDD302	CL254	R001	\N	5	400.00	2025-02-20 10:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	1	16:00:00
250220-PDD303	CL243	R002	\N	5	550.00	2025-02-20 11:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	1	14:15:00
250220-PDD304	CL130	R002	El cliente pidió prioridad de entrega	5	630.00	2025-02-20 12:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	4	14:00:00
250220-PDD305	CL082	R002	Pedido urgente para cliente regular	5	900.00	2025-02-20 14:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	4	15:45:00
250220-PDD307	CL151	R002	\N	5	1050.00	2025-02-20 16:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	2025-02-21 00:00:00	2	13:15:00
250221-PDD308	CL222	R002	\N	5	1500.00	2025-02-21 10:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	3	15:15:00
250221-PDD309	CL243	R002	\N	5	750.00	2025-02-21 11:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	2	15:45:00
250221-PDD310	CL132	R002	\N	5	600.00	2025-02-21 12:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	1	16:45:00
250221-PDD311	CL195	R001	\N	5	1000.00	2025-02-21 14:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	3	16:00:00
250221-PDD312	CL109	R001	\N	5	650.00	2025-02-21 15:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	4	10:00:00
250221-PDD313	CL285	R002	\N	5	450.00	2025-02-21 16:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	2025-02-22 00:00:00	3	08:30:00
250222-PDD314	CL092	R002	Pedido urgente para cliente regular	5	450.00	2025-02-22 10:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	3	15:15:00
250222-PDD315	CL133	R001	\N	5	690.00	2025-02-22 11:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	3	14:15:00
250222-PDD316	CL163	R002	\N	5	800.00	2025-02-22 12:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	1	13:15:00
250222-PDD317	CL160	R001	\N	5	1500.00	2025-02-22 14:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	2	15:45:00
250224-PDD329	CL209	R002	Usar diseño minimalista para este pedido	5	1050.00	2025-02-24 14:00:00	2025-02-25 00:00:00	2025-02-25 16:00:00	2025-02-25 14:00:00	3	09:45:00
250222-PDD318	CL181	R001	\N	5	1620.00	2025-02-22 15:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	4	12:30:00
250222-PDD319	CL303	R001	Usar diseño minimalista para este pedido	5	400.00	2025-02-22 16:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	2025-02-23 00:00:00	2	13:00:00
250223-PDD320	CL032	R001	Usar diseño minimalista para este pedido	5	1200.00	2025-02-23 10:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	2	16:30:00
250223-PDD321	CL190	R001	\N	5	1000.00	2025-02-23 11:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	4	13:45:00
250223-PDD322	CL080	R002	Usar diseño minimalista para este pedido	5	1650.00	2025-02-23 12:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	3	12:45:00
250223-PDD323	CL262	R002	\N	5	650.00	2025-02-23 14:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	4	14:45:00
250223-PDD324	CL051	R002	\N	5	1400.00	2025-02-23 15:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	2	15:30:00
250223-PDD325	CL115	R002	\N	5	450.00	2025-02-23 16:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	2025-02-24 00:00:00	4	11:15:00
250224-PDD326	CL265	R001	Usar diseño minimalista para este pedido	5	450.00	2025-02-24 10:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	2	09:45:00
250224-PDD327	CL213	R002	\N	5	450.00	2025-02-24 11:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	3	08:00:00
250224-PDD328	CL148	R002	\N	5	600.00	2025-02-24 12:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	4	08:30:00
250224-PDD330	CL182	R002	\N	5	200.00	2025-02-24 15:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	3	12:45:00
250224-PDD331	CL063	R001	\N	5	980.00	2025-02-24 16:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	2025-02-25 00:00:00	3	08:00:00
250225-PDD332	CL068	R002	\N	5	450.00	2025-02-25 10:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	3	12:30:00
250225-PDD333	CL032	R002	\N	5	450.00	2025-02-25 11:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	3	14:30:00
250225-PDD334	CL038	R002	\N	5	1000.00	2025-02-25 12:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	4	08:45:00
250225-PDD335	CL099	R001	\N	5	750.00	2025-02-25 14:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	4	13:45:00
250225-PDD336	CL198	R001	\N	5	300.00	2025-02-25 15:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	4	12:30:00
250225-PDD337	CL308	R002	El cliente pidió prioridad de entrega	5	450.00	2025-02-25 16:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	2025-02-26 00:00:00	1	12:30:00
250226-PDD338	CL174	R002	\N	5	800.00	2025-02-26 10:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	1	14:30:00
250301-PDD358	CL171	R002	\N	5	1200.00	2025-03-01 12:00:00	2025-03-02 00:00:00	2025-03-02 13:00:00	2025-03-02 12:00:00	1	11:30:00
250226-PDD340	CL002	R001	\N	5	300.00	2025-02-26 12:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	3	15:00:00
250226-PDD341	CL058	R002	\N	5	1050.00	2025-02-26 14:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	2	11:30:00
250226-PDD342	CL299	R001	Pedido urgente para cliente regular	5	240.00	2025-02-26 15:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	2	12:15:00
250226-PDD343	CL110	R002	El cliente pidió prioridad de entrega	5	950.00	2025-02-26 16:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	2025-02-27 00:00:00	4	13:00:00
250227-PDD344	CL086	R001	\N	5	1000.00	2025-02-27 10:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	3	13:00:00
250227-PDD345	CL292	R002	\N	5	1100.00	2025-02-27 11:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	4	10:00:00
250227-PDD346	CL154	R002	\N	5	800.00	2025-02-27 12:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	3	08:30:00
250227-PDD347	CL120	R001	\N	5	920.00	2025-02-27 14:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	1	10:45:00
250227-PDD348	CL037	R001	\N	5	600.00	2025-02-27 15:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	3	14:30:00
250227-PDD349	CL249	R002	\N	5	450.00	2025-02-27 16:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	2025-02-28 00:00:00	4	09:15:00
250228-PDD350	CL207	R002	\N	5	1600.00	2025-02-28 10:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	3	15:15:00
250228-PDD351	CL029	R002	\N	5	600.00	2025-02-28 11:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	4	14:15:00
250228-PDD352	CL310	R001	\N	5	540.00	2025-02-28 12:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	2	12:45:00
250228-PDD353	CL049	R001	\N	5	900.00	2025-02-28 14:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	4	14:00:00
250228-PDD354	CL151	R002	\N	5	400.00	2025-02-28 15:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	1	16:30:00
250228-PDD355	CL094	R002	Pedido urgente para cliente regular	5	1200.00	2025-02-28 16:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	2025-03-01 00:00:00	2	13:15:00
250301-PDD356	CL269	R002	\N	5	800.00	2025-03-01 10:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	2	11:45:00
250301-PDD357	CL165	R002	\N	5	600.00	2025-03-01 11:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	4	08:45:00
250301-PDD359	CL016	R002	\N	5	1200.00	2025-03-01 14:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	2	08:00:00
250301-PDD360	CL065	R002	\N	5	400.00	2025-03-01 15:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	1	14:00:00
250301-PDD361	CL163	R001	\N	5	950.00	2025-03-01 16:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	2025-03-02 00:00:00	2	10:30:00
250302-PDD362	CL208	R001	\N	5	600.00	2025-03-02 10:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	1	15:00:00
250302-PDD363	CL145	R001	\N	5	1010.00	2025-03-02 11:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	3	11:30:00
250309-PDD407	CL309	R002	\N	5	450.00	2025-03-09 14:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	1	15:00:00
250302-PDD364	CL133	R001	Usar diseño minimalista para este pedido	5	600.00	2025-03-02 12:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	2	16:45:00
250302-PDD365	CL118	R001	\N	5	800.00	2025-03-02 14:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	1	14:45:00
250302-PDD366	CL014	R002	\N	5	900.00	2025-03-02 15:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	2	13:00:00
250302-PDD367	CL189	R002	\N	5	800.00	2025-03-02 16:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	2025-03-03 00:00:00	3	10:15:00
250303-PDD368	CL016	R002	Usar diseño minimalista para este pedido	5	470.00	2025-03-03 10:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2	14:30:00
250303-PDD369	CL126	R002	\N	5	2410.00	2025-03-03 11:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2	11:00:00
250303-PDD370	CL091	R001	\N	5	1300.00	2025-03-03 12:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	3	14:00:00
250303-PDD371	CL145	R002	\N	5	700.00	2025-03-03 14:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2	10:00:00
250303-PDD372	CL148	R001	\N	5	550.00	2025-03-03 15:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	1	15:45:00
250303-PDD373	CL210	R001	\N	5	1050.00	2025-03-03 16:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	2025-03-04 00:00:00	4	14:15:00
250304-PDD374	CL076	R002	\N	5	1160.00	2025-03-04 10:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	1	14:30:00
250304-PDD375	CL156	R001	\N	5	1100.00	2025-03-04 11:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	1	08:45:00
250304-PDD376	CL288	R002	\N	5	150.00	2025-03-04 12:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	3	08:15:00
250304-PDD377	CL067	R002	\N	5	150.00	2025-03-04 14:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	1	09:00:00
250304-PDD378	CL023	R002	\N	5	390.00	2025-03-04 15:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	2	16:45:00
250304-PDD379	CL071	R001	\N	5	1200.00	2025-03-04 16:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	2025-03-05 00:00:00	1	09:30:00
250305-PDD380	CL212	R002	\N	5	450.00	2025-03-05 10:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	1	16:45:00
250305-PDD381	CL221	R002	\N	5	1160.00	2025-03-05 11:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	4	10:30:00
250305-PDD382	CL219	R001	\N	5	600.00	2025-03-05 12:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	3	13:15:00
250305-PDD383	CL071	R002	\N	5	1050.00	2025-03-05 14:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	4	09:45:00
250305-PDD384	CL114	R002	\N	5	960.00	2025-03-05 15:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	1	09:15:00
250305-PDD385	CL294	R002	\N	5	1100.00	2025-03-05 16:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	2025-03-06 00:00:00	3	11:15:00
250306-PDD386	CL133	R002	Cliente quiere ver 2 diseños preliminares	5	2210.00	2025-03-06 10:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	1	11:00:00
250306-PDD387	CL267	R001	\N	5	350.00	2025-03-06 11:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	2	09:30:00
250306-PDD388	CL249	R001	\N	5	450.00	2025-03-06 12:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	1	15:00:00
250307-PDD393	CL148	R001	Cliente rechazo por el material del llavero, se ofrecio cambio de producto	6	120.00	2025-03-07 11:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	4	11:15:00
250306-PDD389	CL249	R002	\N	5	800.00	2025-03-06 14:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	3	09:15:00
250309-PDD404	CL162	R002	Cliente quiere ver 2 diseños preliminares	5	150.00	2025-03-09 10:00:00	2025-03-10 00:00:00	2025-03-10 16:40:00	2025-03-10 15:00:00	1	08:00:00
250306-PDD390	CL020	R001	Usar diseño minimalista para este pedido	5	750.00	2025-03-06 15:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	3	11:15:00
250306-PDD391	CL133	R001	\N	5	810.00	2025-03-06 16:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	2025-03-07 00:00:00	1	13:15:00
250307-PDD392	CL289	R001	El cliente pidió prioridad de entrega	5	600.00	2025-03-07 10:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	1	13:30:00
250308-PDD400	CL289	R002	\N	5	900.00	2025-03-08 12:00:00	2025-03-09 00:00:00	2025-03-09 14:00:00	2025-03-09 12:00:00	2	15:30:00
250307-PDD394	CL157	R001	\N	5	1100.00	2025-03-07 12:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	4	16:15:00
250307-PDD395	CL094	R001	\N	5	1580.00	2025-03-07 14:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	1	13:00:00
250307-PDD396	CL203	R001	\N	5	840.00	2025-03-07 15:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	4	08:45:00
250307-PDD397	CL154	R002	Pedido urgente para cliente regular	5	480.00	2025-03-07 16:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	2025-03-08 00:00:00	3	10:00:00
250308-PDD398	CL008	R001	Usar diseño minimalista para este pedido	5	1300.00	2025-03-08 10:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	3	11:15:00
250308-PDD399	CL305	R001	\N	5	1070.00	2025-03-08 11:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	2	13:15:00
250308-PDD401	CL083	R001	\N	5	1500.00	2025-03-08 14:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	2	16:15:00
250308-PDD402	CL204	R002	El cliente pidió prioridad de entrega	5	510.00	2025-03-08 15:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	4	08:00:00
250308-PDD403	CL120	R002	\N	5	300.00	2025-03-08 16:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	2025-03-09 00:00:00	3	09:45:00
250309-PDD405	CL072	R002	Pedido urgente para cliente regular	5	1000.00	2025-03-09 11:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	3	13:45:00
250309-PDD406	CL163	R002	\N	5	1050.00	2025-03-09 12:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	3	13:45:00
250309-PDD408	CL111	R001	\N	5	660.00	2025-03-09 15:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	3	15:45:00
250309-PDD409	CL310	R001	\N	5	750.00	2025-03-09 16:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	2025-03-10 00:00:00	1	16:45:00
250310-PDD410	CL019	R001	\N	5	750.00	2025-03-10 10:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	4	10:00:00
250310-PDD411	CL150	R001	\N	5	1380.00	2025-03-10 11:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	1	11:45:00
250310-PDD412	CL228	R001	\N	5	120.00	2025-03-10 12:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	3	09:00:00
250310-PDD413	CL146	R002	\N	5	1090.00	2025-03-10 14:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	4	14:30:00
250310-PDD414	CL035	R002	\N	5	980.00	2025-03-10 15:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	2	08:45:00
250310-PDD415	CL021	R001	\N	5	600.00	2025-03-10 16:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	2025-03-11 00:00:00	4	14:15:00
250311-PDD416	CL170	R001	\N	5	1500.00	2025-03-11 10:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	4	12:00:00
250311-PDD417	CL182	R002	\N	5	850.00	2025-03-11 11:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	2	16:00:00
250311-PDD418	CL094	R001	\N	5	1000.00	2025-03-11 12:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	1	12:30:00
250311-PDD419	CL208	R002	\N	5	600.00	2025-03-11 14:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	2	09:30:00
250311-PDD420	CL183	R002	\N	5	500.00	2025-03-11 15:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	1	12:45:00
250311-PDD421	CL162	R001	Pedido urgente para cliente regular	5	900.00	2025-03-11 16:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	2025-03-12 00:00:00	3	11:30:00
250312-PDD422	CL007	R002	\N	5	850.00	2025-03-12 10:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	3	09:30:00
250312-PDD423	CL199	R002	\N	5	920.00	2025-03-12 11:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	1	13:30:00
250312-PDD424	CL050	R002	\N	5	580.00	2025-03-12 12:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	2	15:00:00
250312-PDD425	CL043	R001	Cliente quiere ver 2 diseños preliminares	5	1410.00	2025-03-12 14:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	1	11:45:00
250312-PDD426	CL308	R001	\N	5	1610.00	2025-03-12 15:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	4	13:45:00
250312-PDD427	CL280	R001	\N	5	300.00	2025-03-12 16:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	2025-03-13 00:00:00	2	10:45:00
250313-PDD428	CL144	R001	\N	5	800.00	2025-03-13 10:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	4	10:00:00
250313-PDD429	CL131	R002	\N	5	1060.00	2025-03-13 11:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	2	15:15:00
250313-PDD430	CL271	R001	\N	5	1550.00	2025-03-13 12:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	3	13:45:00
250314-PDD434	CL016	R001	\N	5	350.00	2025-03-14 10:00:00	2025-03-15 00:00:00	2025-03-15 13:50:00	2025-03-15 13:00:00	2	10:45:00
250313-PDD431	CL209	R002	\N	5	1050.00	2025-03-13 14:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	4	14:30:00
250313-PDD432	CL093	R002	El cliente pidió prioridad de entrega	5	750.00	2025-03-13 15:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	2	08:30:00
250313-PDD433	CL198	R001	\N	5	750.00	2025-03-13 16:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	2025-03-14 00:00:00	3	15:15:00
250314-PDD435	CL258	R002	\N	5	400.00	2025-03-14 11:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	4	12:45:00
250316-PDD447	CL240	R002	\N	5	800.00	2025-03-16 11:00:00	2025-03-17 00:00:00	2025-03-17 13:00:00	2025-03-17 09:00:00	4	15:00:00
250314-PDD436	CL085	R002	\N	5	270.00	2025-03-14 12:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	3	16:30:00
250314-PDD437	CL285	R001	\N	5	700.00	2025-03-14 14:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	1	09:30:00
250314-PDD438	CL277	R001	\N	5	400.00	2025-03-14 15:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	4	10:30:00
250314-PDD439	CL264	R002	\N	5	750.00	2025-03-14 16:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	2025-03-15 00:00:00	1	14:00:00
250315-PDD440	CL039	R002	\N	5	600.00	2025-03-15 10:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	3	09:00:00
250315-PDD441	CL275	R001	Usar diseño minimalista para este pedido	5	750.00	2025-03-15 11:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2	15:00:00
250315-PDD442	CL281	R002	\N	5	840.00	2025-03-15 12:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	4	08:45:00
250315-PDD443	CL190	R001	\N	5	890.00	2025-03-15 14:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	1	11:15:00
250315-PDD444	CL088	R001	\N	5	1040.00	2025-03-15 15:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2	10:45:00
250315-PDD445	CL034	R001	\N	5	700.00	2025-03-15 16:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2025-03-16 00:00:00	2	15:15:00
250316-PDD446	CL054	R001	\N	5	400.00	2025-03-16 10:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	4	08:45:00
250316-PDD448	CL024	R002	\N	5	540.00	2025-03-16 12:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	4	09:00:00
250316-PDD449	CL131	R001	Cliente quiere ver 2 diseños preliminares	5	950.00	2025-03-16 14:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	4	10:00:00
250316-PDD450	CL284	R001	\N	5	1200.00	2025-03-16 15:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	2	14:15:00
250316-PDD451	CL111	R002	\N	5	1250.00	2025-03-16 16:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	2025-03-17 00:00:00	2	14:15:00
250317-PDD452	CL259	R002	\N	5	670.00	2025-03-17 10:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	1	16:00:00
250317-PDD455	CL228	R002	Cliente no quiso aceptar pedido.	6	750.00	2025-03-17 14:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	4	13:45:00
250317-PDD453	CL085	R002	Usar diseño minimalista para este pedido	5	1500.00	2025-03-17 11:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	4	14:45:00
250317-PDD454	CL046	R002	\N	5	750.00	2025-03-17 12:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	1	10:30:00
250317-PDD456	CL003	R002	\N	5	600.00	2025-03-17 15:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	4	10:15:00
250317-PDD457	CL002	R001	\N	5	1050.00	2025-03-17 16:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	2025-03-18 00:00:00	3	15:15:00
250318-PDD458	CL090	R002	\N	5	950.00	2025-03-18 10:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	1	10:00:00
250318-PDD459	CL165	R002	Cliente quiere ver 2 diseños preliminares	5	1350.00	2025-03-18 11:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	1	16:30:00
250318-PDD460	CL029	R001	\N	5	1350.00	2025-03-18 12:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	2	12:30:00
250318-PDD461	CL135	R001	\N	5	750.00	2025-03-18 14:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	3	15:30:00
250318-PDD462	CL187	R001	\N	5	600.00	2025-03-18 15:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	1	13:00:00
250318-PDD463	CL291	R001	\N	5	1100.00	2025-03-18 16:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	2025-03-19 00:00:00	3	09:00:00
250319-PDD464	CL156	R002	\N	5	1350.00	2025-03-19 10:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	4	16:15:00
250319-PDD465	CL235	R002	\N	5	150.00	2025-03-19 11:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	4	13:30:00
250319-PDD466	CL140	R001	\N	5	1350.00	2025-03-19 12:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	3	14:45:00
250319-PDD467	CL104	R001	\N	5	300.00	2025-03-19 14:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	3	10:30:00
250319-PDD468	CL259	R001	Usar diseño minimalista para este pedido	5	1270.00	2025-03-19 15:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	1	11:15:00
250319-PDD469	CL106	R002	\N	5	750.00	2025-03-19 16:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	2025-03-20 00:00:00	4	15:30:00
250320-PDD470	CL211	R002	Cliente quiere ver 2 diseños preliminares	5	1250.00	2025-03-20 10:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	1	14:30:00
250320-PDD471	CL133	R001	\N	5	800.00	2025-03-20 11:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	4	14:30:00
250320-PDD472	CL008	R002	\N	5	790.00	2025-03-20 12:00:00	2025-03-21 00:00:00	2025-03-21 14:00:00	2025-03-21 08:00:00	2	11:30:00
250320-PDD473	CL187	R002	\N	5	1700.00	2025-03-20 14:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	1	12:15:00
250322-PDD482	CL024	R002	\N	5	1480.00	2025-03-22 10:00:00	2025-03-23 00:00:00	2025-03-23 11:20:00	2025-03-23 09:00:00	3	16:45:00
250320-PDD474	CL147	R001	\N	5	150.00	2025-03-20 15:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	4	11:15:00
250323-PDD490	CL021	R002	\N	5	800.00	2025-03-23 12:00:00	2025-03-24 00:00:00	2025-03-24 16:00:00	2025-03-24 10:00:00	4	14:15:00
250320-PDD475	CL109	R002	\N	5	1550.00	2025-03-20 16:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	2025-03-21 00:00:00	2	09:00:00
250321-PDD476	CL003	R002	\N	5	400.00	2025-03-21 10:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	1	12:30:00
250321-PDD477	CL099	R002	\N	5	1400.00	2025-03-21 11:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	3	09:30:00
250321-PDD478	CL208	R001	\N	5	1200.00	2025-03-21 12:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	2	14:00:00
250321-PDD479	CL003	R001	Usar diseño minimalista para este pedido	5	300.00	2025-03-21 14:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	1	08:00:00
250321-PDD480	CL194	R001	\N	5	750.00	2025-03-21 15:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	4	16:00:00
250321-PDD481	CL252	R001	\N	5	450.00	2025-03-21 16:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	2025-03-22 00:00:00	2	10:15:00
250322-PDD483	CL147	R001	Pedido urgente para cliente regular	5	1180.00	2025-03-22 11:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	2	08:45:00
250322-PDD484	CL129	R002	\N	5	1170.00	2025-03-22 12:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	1	11:00:00
250322-PDD485	CL099	R002	\N	5	1050.00	2025-03-22 14:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	4	12:00:00
250322-PDD486	CL165	R002	El cliente pidió prioridad de entrega	5	1000.00	2025-03-22 15:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	1	11:00:00
250322-PDD487	CL180	R001	\N	5	150.00	2025-03-22 16:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	2025-03-23 00:00:00	3	14:30:00
250323-PDD488	CL116	R001	\N	5	600.00	2025-03-23 10:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	3	13:45:00
250323-PDD489	CL206	R001	\N	5	600.00	2025-03-23 11:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	2	09:30:00
250323-PDD491	CL117	R001	\N	5	1460.00	2025-03-23 14:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	3	15:00:00
250323-PDD492	CL116	R002	\N	5	1520.00	2025-03-23 15:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	4	16:30:00
250323-PDD493	CL235	R002	\N	5	500.00	2025-03-23 16:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	2025-03-24 00:00:00	3	12:00:00
250403-PDD558	CL250	R001	\N	5	1550.00	2025-04-03 15:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	1	09:00:00
250403-PDD559	CL101	R001	\N	5	600.00	2025-04-03 16:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	4	13:30:00
250324-PDD494	CL154	R002	Cliente quiere ver 2 diseños preliminares	5	750.00	2025-03-24 10:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	2	10:15:00
250324-PDD495	CL232	R002	\N	5	1100.00	2025-03-24 11:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	2	15:45:00
250324-PDD496	CL074	R001	\N	5	150.00	2025-03-24 12:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	3	13:15:00
250324-PDD497	CL248	R001	\N	5	150.00	2025-03-24 14:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	1	13:30:00
250325-PDD502	CL026	R002	\N	5	100.00	2025-03-25 12:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	4	09:15:00
250324-PDD499	CL036	R001	\N	5	300.00	2025-03-24 16:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	2025-03-25 00:00:00	2	08:45:00
250325-PDD503	CL008	R002	\N	5	1400.00	2025-03-25 14:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	4	12:15:00
250325-PDD504	CL095	R002	\N	5	450.00	2025-03-25 15:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	1	11:15:00
250325-PDD500	CL168	R001	\N	5	300.00	2025-03-25 10:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	4	09:30:00
250325-PDD501	CL272	R002	\N	5	1180.00	2025-03-25 11:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	3	11:30:00
250325-PDD505	CL019	R001	\N	5	750.00	2025-03-25 16:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	2025-03-26 00:00:00	1	08:15:00
250326-PDD506	CL200	R001	\N	5	1000.00	2025-03-26 10:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	1	08:45:00
250326-PDD508	CL183	R001	\N	5	150.00	2025-03-26 12:00:00	2025-03-27 00:00:00	2025-03-27 14:00:00	2025-03-27 10:00:00	4	14:45:00
250326-PDD507	CL005	R001	\N	5	450.00	2025-03-26 11:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	4	09:45:00
250324-PDD498	CL099	R001	\N	5	340.00	2025-03-24 15:00:00	2025-03-25 00:00:00	2025-03-25 11:00:00	2025-03-25 10:00:00	3	10:15:00
250326-PDD509	CL087	R002	\N	5	540.00	2025-03-26 14:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	1	15:00:00
250326-PDD510	CL084	R001	\N	5	800.00	2025-03-26 15:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	3	09:00:00
250326-PDD511	CL077	R001	\N	5	450.00	2025-03-26 16:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	2025-03-27 00:00:00	2	12:15:00
250327-PDD512	CL118	R002	\N	5	1020.00	2025-03-27 10:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	3	16:15:00
250327-PDD513	CL088	R002	Pedido urgente para cliente regular	5	1100.00	2025-03-27 11:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	1	08:00:00
250327-PDD514	CL105	R002	\N	5	1400.00	2025-03-27 12:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	4	12:45:00
250327-PDD515	CL030	R002	\N	5	750.00	2025-03-27 14:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	4	13:30:00
250327-PDD516	CL137	R001	\N	5	200.00	2025-03-27 15:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	4	12:15:00
250327-PDD517	CL294	R002	\N	5	1200.00	2025-03-27 16:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	2025-03-28 00:00:00	2	15:30:00
250328-PDD518	CL160	R002	\N	5	800.00	2025-03-28 10:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	2	12:30:00
250328-PDD519	CL009	R002	\N	5	1350.00	2025-03-28 11:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	1	16:30:00
250328-PDD520	CL025	R001	\N	5	1150.00	2025-03-28 12:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	2	10:45:00
250328-PDD521	CL013	R001	Pedido urgente para cliente regular	5	150.00	2025-03-28 14:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	3	09:00:00
250328-PDD522	CL062	R001	\N	5	1160.00	2025-03-28 15:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	1	08:45:00
250328-PDD523	CL191	R002	\N	5	850.00	2025-03-28 16:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	2025-03-29 00:00:00	4	15:00:00
250329-PDD524	CL213	R002	\N	5	150.00	2025-03-29 10:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	1	13:00:00
250331-PDD539	CL033	R001	\N	5	690.00	2025-03-31 14:00:00	2025-04-01 00:00:00	2025-04-01 12:30:00	2025-04-01 10:30:00	1	11:30:00
250329-PDD526	CL303	R002	\N	5	450.00	2025-03-29 12:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	2	08:45:00
250329-PDD527	CL194	R001	\N	5	1400.00	2025-03-29 14:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	4	10:30:00
250329-PDD528	CL057	R001	\N	5	1100.00	2025-03-29 15:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	2	14:30:00
250329-PDD525	CL019	R002	\N	5	1050.00	2025-03-29 11:00:00	2025-03-30 00:00:00	2025-03-30 15:00:00	2025-03-30 13:00:00	1	08:30:00
250329-PDD529	CL185	R002	\N	5	150.00	2025-03-29 16:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	2025-03-30 00:00:00	3	10:00:00
250330-PDD530	CL243	R002	\N	5	720.00	2025-03-30 10:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	1	10:30:00
250330-PDD531	CL226	R002	\N	5	1350.00	2025-03-30 11:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	2	15:00:00
250330-PDD532	CL279	R001	\N	5	340.00	2025-03-30 12:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	4	15:00:00
250330-PDD533	CL007	R002	\N	5	840.00	2025-03-30 14:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	1	14:45:00
250330-PDD534	CL285	R001	Cliente quiere ver 2 diseños preliminares	5	930.00	2025-03-30 15:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	4	13:00:00
250330-PDD535	CL237	R002	\N	5	950.00	2025-03-30 16:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	2025-03-31 00:00:00	4	15:30:00
250331-PDD536	CL057	R001	\N	5	800.00	2025-03-31 10:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	4	15:15:00
250331-PDD537	CL223	R001	\N	5	800.00	2025-03-31 11:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2	13:30:00
250331-PDD538	CL091	R001	\N	5	600.00	2025-03-31 12:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2	11:30:00
250331-PDD540	CL104	R001	\N	5	850.00	2025-03-31 15:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2	16:45:00
250331-PDD541	CL160	R001	\N	5	1000.00	2025-03-31 16:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2025-04-01 00:00:00	2	10:00:00
250401-PDD542	CL126	R002	\N	5	300.00	2025-04-01 10:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	1	15:30:00
250401-PDD543	CL299	R001	\N	5	800.00	2025-04-01 11:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	4	15:15:00
250401-PDD544	CL013	R002	Usar diseño minimalista para este pedido	5	600.00	2025-04-01 12:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	2	13:15:00
250401-PDD545	CL260	R001	\N	5	900.00	2025-04-01 14:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	1	13:30:00
250401-PDD546	CL125	R001	\N	5	1870.00	2025-04-01 15:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	2	14:45:00
250401-PDD547	CL028	R001	\N	5	300.00	2025-04-01 16:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	2025-04-02 00:00:00	4	08:45:00
250402-PDD552	CL032	R001	\N	5	1200.00	2025-04-02 15:00:00	2025-04-03 00:00:00	2025-04-03 13:40:00	2025-04-03 12:00:00	1	16:00:00
250402-PDD548	CL039	R001	Pedido urgente para cliente regular	5	550.00	2025-04-02 10:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	1	10:30:00
250402-PDD549	CL266	R002	\N	5	600.00	2025-04-02 11:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	3	08:45:00
250402-PDD550	CL022	R002	\N	5	600.00	2025-04-02 12:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	3	15:30:00
250402-PDD551	CL072	R002	\N	5	1200.00	2025-04-02 14:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	1	11:45:00
250402-PDD553	CL017	R001	\N	5	300.00	2025-04-02 16:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	2025-04-03 00:00:00	1	08:45:00
250403-PDD554	CL250	R002	\N	5	450.00	2025-04-03 10:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	3	14:45:00
250403-PDD555	CL206	R001	\N	5	1600.00	2025-04-03 11:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	4	14:15:00
250403-PDD556	CL039	R001	\N	5	900.00	2025-04-03 12:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	1	16:00:00
250403-PDD557	CL282	R002	\N	5	600.00	2025-04-03 14:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	2025-04-04 00:00:00	1	10:45:00
250404-PDD560	CL260	R001	\N	5	870.00	2025-04-04 10:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	3	11:15:00
250404-PDD561	CL138	R002	\N	5	1140.00	2025-04-04 11:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	2	11:45:00
250404-PDD562	CL181	R001	\N	5	2000.00	2025-04-04 12:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	4	16:00:00
250404-PDD563	CL094	R001	Usar diseño minimalista para este pedido	5	450.00	2025-04-04 14:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	3	14:45:00
250404-PDD564	CL307	R001	\N	5	650.00	2025-04-04 15:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	1	14:15:00
250404-PDD565	CL271	R001	Pedido urgente para cliente regular	5	900.00	2025-04-04 16:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	2025-04-05 00:00:00	1	11:45:00
250405-PDD566	CL302	R001	\N	5	600.00	2025-04-05 10:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	1	10:45:00
250405-PDD567	CL082	R001	\N	5	1200.00	2025-04-05 11:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	1	10:00:00
250405-PDD568	CL091	R002	\N	5	1370.00	2025-04-05 12:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	2	16:15:00
250405-PDD570	CL277	R002	\N	5	100.00	2025-04-05 15:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	3	16:30:00
250405-PDD571	CL077	R002	El cliente pidió prioridad de entrega	5	290.00	2025-04-05 16:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	2025-04-06 00:00:00	3	11:15:00
250406-PDD572	CL031	R002	\N	5	900.00	2025-04-06 10:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	2	14:15:00
250406-PDD573	CL086	R002	\N	5	1150.00	2025-04-06 11:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	4	15:45:00
250406-PDD574	CL147	R002	\N	5	950.00	2025-04-06 12:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	4	16:00:00
250406-PDD575	CL200	R001	\N	5	600.00	2025-04-06 14:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	2	12:45:00
250406-PDD576	CL291	R001	\N	5	700.00	2025-04-06 15:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	1	09:45:00
250406-PDD577	CL125	R001	Cliente quiere ver 2 diseños preliminares	5	450.00	2025-04-06 16:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	2025-04-07 00:00:00	1	16:30:00
250407-PDD578	CL300	R001	\N	5	1200.00	2025-04-07 10:00:00	2025-04-08 00:00:00	2025-04-08 00:00:00	2025-04-08 00:00:00	2	11:30:00
250407-PDD581	CL144	R002	Usar diseño minimalista para este pedido	4	520.00	2025-04-07 14:00:00	2025-04-08 00:00:00	2025-04-08 00:00:00	2025-04-08 00:00:00	3	08:45:00
250407-PDD579	CL077	R001	\N	5	400.00	2025-04-07 11:00:00	2025-04-08 00:00:00	2025-04-08 00:00:00	2025-04-08 00:00:00	2	11:45:00
250407-PDD580	CL253	R001	\N	5	450.00	2025-04-07 12:00:00	2025-04-08 00:00:00	2025-04-08 00:00:00	2025-04-08 00:00:00	3	12:30:00
250408-PDD589	CL024	R002	Usar diseño minimalista para este pedido	1	600.00	2025-04-08 16:00:00	2025-04-09 00:00:00	\N	2025-04-09 00:00:00	2	09:15:00
250408-PDD588	CL239	R001	\N	2	450.00	2025-04-08 15:00:00	2025-04-09 00:00:00	\N	2025-04-09 00:00:00	4	14:45:00
250408-PDD587	CL171	R002	\N	3	450.00	2025-04-08 14:00:00	2025-04-09 00:00:00	\N	2025-04-09 00:00:00	2	13:00:00
250408-PDD586	CL106	R001	\N	3	850.00	2025-04-08 12:00:00	2025-04-09 00:00:00	\N	2025-04-09 00:00:00	2	14:15:00
250408-PDD585	CL092	R001	\N	2	910.00	2025-04-08 11:00:00	2025-04-09 00:00:00	\N	2025-04-09 00:00:00	3	08:45:00
250408-PDD584	CL039	R001	\N	2	800.00	2025-04-08 10:00:00	2025-04-09 00:00:00	\N	2025-04-09 00:00:00	3	13:30:00
250407-PDD583	CL287	R001	\N	4	1550.00	2025-04-07 16:00:00	2025-04-08 00:00:00	\N	2025-04-08 00:00:00	2	10:00:00
250407-PDD582	CL202	R001	\N	4	680.00	2025-04-07 15:00:00	2025-04-08 00:00:00	\N	2025-04-08 00:00:00	3	16:00:00
250405-PDD569	CL182	R001	Pedido urgente para cliente regular	5	300.00	2025-04-05 14:00:00	2025-04-06 00:00:00	2025-04-06 15:30:00	2025-04-06 10:30:00	3	13:00:00
250113-PDD078	CL008	R001	\n[2025-04-24] Cambio de estado: En Espera	3	600.00	2025-01-13 15:00:00	2025-04-24 05:19:55.740929	2025-01-14 00:00:00	2025-01-14 00:00:00	2	11:00:00
\.


--
-- Data for Name: producto_especificaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.producto_especificaciones (producto_id, especificacion_id) FROM stdin;
CAM	1
CAM	2
TAZ	2
TAZ	4
LLA	3
LLA	5
TER	6
TER	2
GOR	1
GOR	2
\.


--
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.productos (producto_id, nombre, descripcion, precio_base) FROM stdin;
TAZ	Taza	Taza sublimable	150
GOR	Gorra	Gorra sublimable	150
LLA	Llavero	Llavero sublimable	100
TER	Termo	Termo sublimable	170
CAM	Camisa	Camisa sublimable	150
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refresh_tokens (id, token, usuario_id, expires_at, created_at) FROM stdin;
3	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c3VhcmlvX2lkIjoiQTAwMyIsImlhdCI6MTc0NDIyMTYzNiwiZXhwIjoxNzQ0ODI2NDM2fQ.Wa4YAtvropGCKSqsqwRAq3RwxCjd5aUETIE_Kk0Jvsg	A003	2025-04-16 12:00:36.61	2025-04-09 06:15:39.567246
14	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c3VhcmlvX2lkIjoiQTAwNCIsImlhdCI6MTc0NDMyNjA4MiwiZXhwIjoxNzQ0OTMwODgyfQ.OVtvS12tnqkqcRVOs_8pSawfHdSAI92OoC5tUYmamEo	A004	2025-04-17 17:01:22.216	2025-04-09 18:21:19.381056
1	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c3VhcmlvX2lkIjoiQTAwMiIsImlhdCI6MTc1NDAyMDE2OSwiZXhwIjoxNzU0NjI0OTY5fQ.V5V8Z2KWm_nzU7ZnhXqmdqKk98ic1VVGDU-wzTO-nuE	A002	2025-08-07 21:49:29.4	2025-04-09 05:48:17.609095
\.


--
-- Data for Name: rol; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rol (rol_id, nombre) FROM stdin;
1	Administrador
2	Recepcion
3	Produccion
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (usuario_id, nombre, nombre_usuario, rol, correo, contrasena) FROM stdin;
R001	Jimi Vega	Jimv	2	eljimi@gmail.com	contradejimi
P001	Juan Vasquez	vazquezj	3	correo@gmail.com	contradejuan
A001	Roberto Sanchez	ron_sanz	1	micorreo@gmail.com	contraderoberto
R002	Dania Guerra	daniag	2	\N	daniag123
A002	Diego Rios	driosp	1	driosp@unah.hn	$2b$10$aeISlv/5IPOGRxsAIuXHq.7bxtFB5smxVw44j5HrN314FGX97UK6G
A003	Ana Oseguera	kaemun	1	akoseguera@unah.hn	$2b$10$K6CZCyTjDwjBTOZsPE95d.7mzW7ekvVCE3gyQuUdGPamB9TRhLa1a
A004	Diana Vega	anaid	1	diana.vega@unah.hn	$2b$10$O9cz1QBDMTO.hY3ThJnkaO.jdMUYTtNiHhLtRvn.t.me8R.9vjesa
\.


--
-- Data for Name: valor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.valor (especificacion_id, valor, precio, valor_id) FROM stdin;
1	6	0	1
1	S	50	2
1	8	0	3
1	12	0	4
1	14	0	5
1	4	0	6
1	XL	50	7
1	XXL	50	8
1	L	50	9
1	M	50	10
2	Verde	0	11
2	Rosado	0	12
2	Morado	0	13
2	Gris	0	14
2	Blanco	0	15
2	Rojo	0	16
2	Negro	0	17
2	Amarillo	0	18
2	Azul	0	19
3	Madera	20	20
3	PVC	0	21
3	Metal	50	22
4	Normal	0	23
4	Magica	50	24
5	Circular	0	25
5	Corazon	0	26
5	Rectangular	0	27
6	Aluminio	120	28
6	Plastico	0	29
\.


--
-- Data for Name: variante_valores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.variante_valores (variante_valores_id, variante_id, valor_id) FROM stdin;
1	1	24
2	1	15
3	2	23
4	2	17
5	3	24
6	3	19
7	4	23
8	4	16
9	5	2
10	5	16
11	6	10
12	6	19
13	7	9
14	7	17
15	8	7
16	8	15
17	9	20
18	9	25
19	10	22
20	10	26
21	11	21
22	11	27
23	12	22
24	12	25
25	13	28
26	13	18
27	14	29
28	14	19
29	15	28
30	15	16
31	16	29
32	16	11
33	17	7
34	17	17
35	18	10
36	18	19
37	19	9
38	19	11
39	20	2
40	20	15
\.


--
-- Data for Name: variantes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.variantes (variante_id, producto_id, sku, precio_total, stock) FROM stdin;
1	TAZ	TAZ-Bla-Mag	200.00	44
2	TAZ	TAZ-Neg-Nor	150.00	48
3	TAZ	TAZ-Azu-Mag	200.00	47
4	TAZ	TAZ-Roj-Nor	150.00	48
5	GOR	GOR-S-Roj	200.00	39
6	GOR	GOR-M-Azu	200.00	41
7	GOR	GOR-L-Neg	200.00	37
8	GOR	GOR-XL-Bla	200.00	33
9	LLA	LLA-Mad-Cir	120.00	41
10	LLA	LLA-Met-Cor	150.00	39
11	LLA	LLA-PVC-Rec	100.00	43
12	LLA	LLA-Met-Cir	150.00	36
13	TER	TER-Ama-Alu	290.00	31
14	TER	TER-Azu-Pla	170.00	23
15	TER	TER-Roj-Alu	290.00	40
16	TER	TER-Ver-Pla	170.00	24
17	CAM	CAM-XL-Neg	200.00	42
18	CAM	CAM-M-Azu	200.00	50
19	CAM	CAM-L-Ver	200.00	31
20	CAM	CAM-S-Bla	200.00	26
\.


--
-- Name: bitacora_bitacora_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bitacora_bitacora_id_seq', 99, true);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.refresh_tokens_id_seq', 66, true);


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_usuario_seq', 1, false);


--
-- Name: valor_valor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.valor_valor_id_seq', 29, true);


--
-- Name: variante_valores_variante_valores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.variante_valores_variante_valores_id_seq', 40, true);


--
-- Name: variantes_variante_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.variantes_variante_id_seq', 20, true);


--
-- Name: bitacora bitacora_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bitacora
    ADD CONSTRAINT bitacora_pkey PRIMARY KEY (bitacora_id);


--
-- Name: clientes cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (cliente_id);


--
-- Name: clientes cliente_telefono_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT cliente_telefono_key UNIQUE (telefono);


--
-- Name: detalle_pedido detalle_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pkey PRIMARY KEY (detalle_pedido_id);


--
-- Name: especificacion especificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.especificacion
    ADD CONSTRAINT especificacion_pkey PRIMARY KEY (especificacion_id);


--
-- Name: estados estado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estados
    ADD CONSTRAINT estado_pkey PRIMARY KEY (estado_id);


--
-- Name: metodo_envio metodo_envio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.metodo_envio
    ADD CONSTRAINT metodo_envio_pkey PRIMARY KEY (metodo_id);


--
-- Name: pedido_especificacion pedido_especificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_especificacion
    ADD CONSTRAINT pedido_especificacion_pkey PRIMARY KEY (pedido_especificacion_id);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (pedido_id);


--
-- Name: producto_especificaciones producto_especificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_especificaciones
    ADD CONSTRAINT producto_especificaciones_pkey PRIMARY KEY (producto_id, especificacion_id);


--
-- Name: productos producto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT producto_pkey PRIMARY KEY (producto_id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_usuario_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_usuario_id_key UNIQUE (usuario_id);


--
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (rol_id);


--
-- Name: usuarios usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (usuario_id);


--
-- Name: usuarios usuartio_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuartio_key UNIQUE (nombre_usuario);


--
-- Name: valor valor_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.valor
    ADD CONSTRAINT valor_pk PRIMARY KEY (valor_id);


--
-- Name: valor valor_valor_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.valor
    ADD CONSTRAINT valor_valor_unique UNIQUE (valor);


--
-- Name: variante_valores variante_valores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variante_valores
    ADD CONSTRAINT variante_valores_pkey PRIMARY KEY (variante_valores_id);


--
-- Name: variantes variantes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variantes
    ADD CONSTRAINT variantes_pkey PRIMARY KEY (variante_id);


--
-- Name: idx_clientes_telefono; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clientes_telefono ON public.clientes USING btree (telefono);


--
-- Name: idx_refresh_tokens_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_refresh_tokens_token ON public.refresh_tokens USING btree (token);


--
-- Name: idx_refresh_tokens_usuario_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_refresh_tokens_usuario_id ON public.refresh_tokens USING btree (usuario_id);


--
-- Name: idx_usuarios_nombre_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usuarios_nombre_usuario ON public.usuarios USING btree (nombre_usuario);


--
-- Name: variante_valores after_variante_valores_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER after_variante_valores_insert AFTER INSERT ON public.variante_valores FOR EACH ROW EXECUTE FUNCTION public.calculate_variant_details();


--
-- Name: pedido_especificacion trigger_actualizar_precio_unitario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_actualizar_precio_unitario AFTER INSERT OR DELETE ON public.pedido_especificacion FOR EACH ROW EXECUTE FUNCTION public.actualizar_precio_unitario();


--
-- Name: detalle_pedido trigger_actualizar_total_pedido_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_actualizar_total_pedido_delete AFTER DELETE ON public.detalle_pedido FOR EACH ROW EXECUTE FUNCTION public.actualizar_total_pedido();


--
-- Name: detalle_pedido trigger_actualizar_total_pedido_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_actualizar_total_pedido_insert AFTER INSERT ON public.detalle_pedido FOR EACH ROW EXECUTE FUNCTION public.actualizar_total_pedido();


--
-- Name: detalle_pedido trigger_actualizar_total_pedido_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_actualizar_total_pedido_update AFTER UPDATE ON public.detalle_pedido FOR EACH ROW EXECUTE FUNCTION public.actualizar_total_pedido();


--
-- Name: detalle_pedido trigger_set_precio_unitario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_set_precio_unitario BEFORE INSERT ON public.detalle_pedido FOR EACH ROW EXECUTE FUNCTION public.set_precio_unitario();


--
-- Name: detalle_pedido detalle_pedido_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pedido_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(pedido_id) ON DELETE CASCADE;


--
-- Name: detalle_pedido detalle_pedido_producto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_producto_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(producto_id);


--
-- Name: variantes fk_producto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variantes
    ADD CONSTRAINT fk_producto FOREIGN KEY (producto_id) REFERENCES public.productos(producto_id) ON DELETE CASCADE;


--
-- Name: variante_valores fk_valor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variante_valores
    ADD CONSTRAINT fk_valor FOREIGN KEY (valor_id) REFERENCES public.valor(valor_id) ON DELETE CASCADE;


--
-- Name: variante_valores fk_variante; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variante_valores
    ADD CONSTRAINT fk_variante FOREIGN KEY (variante_id) REFERENCES public.variantes(variante_id) ON DELETE CASCADE;


--
-- Name: pedido_especificacion pedido_especificacion_detalle_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_especificacion
    ADD CONSTRAINT pedido_especificacion_detalle_pedido_fkey FOREIGN KEY (detalle_pedido_id) REFERENCES public.detalle_pedido(detalle_pedido_id) ON DELETE CASCADE;


--
-- Name: pedido_especificacion pedido_especificacion_especificacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_especificacion
    ADD CONSTRAINT pedido_especificacion_especificacion_fkey FOREIGN KEY (especificacion_id) REFERENCES public.especificacion(especificacion_id);


--
-- Name: pedido_especificacion pedido_especificacion_valor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_especificacion
    ADD CONSTRAINT pedido_especificacion_valor_fkey FOREIGN KEY (valor) REFERENCES public.valor(valor);


--
-- Name: pedidos pedido_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedido_usuario_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(usuario_id);


--
-- Name: pedidos pedidos_cliente_fket; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_cliente_fket FOREIGN KEY (cliente_id) REFERENCES public.clientes(cliente_id);


--
-- Name: pedidos pedidos_estado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_estado_fkey FOREIGN KEY (estado_id) REFERENCES public.estados(estado_id);


--
-- Name: pedidos pedidos_metodo_envio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_metodo_envio_fkey FOREIGN KEY (metodo_id) REFERENCES public.metodo_envio(metodo_id);


--
-- Name: producto_especificaciones producto_especificaciones_especificacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_especificaciones
    ADD CONSTRAINT producto_especificaciones_especificacion_id_fkey FOREIGN KEY (especificacion_id) REFERENCES public.especificacion(especificacion_id);


--
-- Name: producto_especificaciones producto_especificaciones_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producto_especificaciones
    ADD CONSTRAINT producto_especificaciones_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(producto_id);


--
-- Name: refresh_tokens refresh_tokens_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(usuario_id);


--
-- Name: usuarios usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuario_fkey FOREIGN KEY (rol) REFERENCES public.rol(rol_id);


--
-- Name: valor valor_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.valor
    ADD CONSTRAINT valor_fk FOREIGN KEY (especificacion_id) REFERENCES public.especificacion(especificacion_id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION actualizar_precio_unitario(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.actualizar_precio_unitario() TO anon;
GRANT ALL ON FUNCTION public.actualizar_precio_unitario() TO authenticated;
GRANT ALL ON FUNCTION public.actualizar_precio_unitario() TO service_role;


--
-- Name: FUNCTION actualizar_total_pedido(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.actualizar_total_pedido() TO anon;
GRANT ALL ON FUNCTION public.actualizar_total_pedido() TO authenticated;
GRANT ALL ON FUNCTION public.actualizar_total_pedido() TO service_role;


--
-- Name: FUNCTION calculate_variant_details(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calculate_variant_details() TO anon;
GRANT ALL ON FUNCTION public.calculate_variant_details() TO authenticated;
GRANT ALL ON FUNCTION public.calculate_variant_details() TO service_role;


--
-- Name: PROCEDURE crear_pedido_con_validacion(IN p_pedido_id character varying, IN p_cliente_id character varying, IN p_usuario_id character varying, IN p_notas text, IN p_metodo_id integer, IN p_fecha_estimada_entrega timestamp without time zone, IN p_hora_estimada_entrega time without time zone, IN p_detalles jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON PROCEDURE public.crear_pedido_con_validacion(IN p_pedido_id character varying, IN p_cliente_id character varying, IN p_usuario_id character varying, IN p_notas text, IN p_metodo_id integer, IN p_fecha_estimada_entrega timestamp without time zone, IN p_hora_estimada_entrega time without time zone, IN p_detalles jsonb) TO anon;
GRANT ALL ON PROCEDURE public.crear_pedido_con_validacion(IN p_pedido_id character varying, IN p_cliente_id character varying, IN p_usuario_id character varying, IN p_notas text, IN p_metodo_id integer, IN p_fecha_estimada_entrega timestamp without time zone, IN p_hora_estimada_entrega time without time zone, IN p_detalles jsonb) TO authenticated;
GRANT ALL ON PROCEDURE public.crear_pedido_con_validacion(IN p_pedido_id character varying, IN p_cliente_id character varying, IN p_usuario_id character varying, IN p_notas text, IN p_metodo_id integer, IN p_fecha_estimada_entrega timestamp without time zone, IN p_hora_estimada_entrega time without time zone, IN p_detalles jsonb) TO service_role;


--
-- Name: FUNCTION set_precio_unitario(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_precio_unitario() TO anon;
GRANT ALL ON FUNCTION public.set_precio_unitario() TO authenticated;
GRANT ALL ON FUNCTION public.set_precio_unitario() TO service_role;


--
-- Name: FUNCTION verificar_disponibilidad_inventario(p_producto_id character varying, p_cantidad integer, p_especificaciones jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.verificar_disponibilidad_inventario(p_producto_id character varying, p_cantidad integer, p_especificaciones jsonb) TO anon;
GRANT ALL ON FUNCTION public.verificar_disponibilidad_inventario(p_producto_id character varying, p_cantidad integer, p_especificaciones jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.verificar_disponibilidad_inventario(p_producto_id character varying, p_cantidad integer, p_especificaciones jsonb) TO service_role;


--
-- Name: TABLE bitacora; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.bitacora TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.bitacora TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.bitacora TO service_role;


--
-- Name: SEQUENCE bitacora_bitacora_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.bitacora_bitacora_id_seq TO anon;
GRANT ALL ON SEQUENCE public.bitacora_bitacora_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.bitacora_bitacora_id_seq TO service_role;


--
-- Name: TABLE clientes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.clientes TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.clientes TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.clientes TO service_role;


--
-- Name: TABLE detalle_pedido; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.detalle_pedido TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.detalle_pedido TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.detalle_pedido TO service_role;


--
-- Name: TABLE especificacion; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.especificacion TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.especificacion TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.especificacion TO service_role;


--
-- Name: TABLE estados; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.estados TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.estados TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.estados TO service_role;


--
-- Name: TABLE metodo_envio; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.metodo_envio TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.metodo_envio TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.metodo_envio TO service_role;


--
-- Name: TABLE pedido_especificacion; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pedido_especificacion TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pedido_especificacion TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pedido_especificacion TO service_role;


--
-- Name: TABLE pedidos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pedidos TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pedidos TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pedidos TO service_role;


--
-- Name: TABLE producto_especificaciones; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.producto_especificaciones TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.producto_especificaciones TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.producto_especificaciones TO service_role;


--
-- Name: TABLE productos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.productos TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.productos TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.productos TO service_role;


--
-- Name: TABLE refresh_tokens; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.refresh_tokens TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.refresh_tokens TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.refresh_tokens TO service_role;


--
-- Name: SEQUENCE refresh_tokens_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO anon;
GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO service_role;


--
-- Name: TABLE rol; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.rol TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.rol TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.rol TO service_role;


--
-- Name: TABLE usuarios; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.usuarios TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.usuarios TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.usuarios TO service_role;


--
-- Name: SEQUENCE usuarios_id_usuario_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.usuarios_id_usuario_seq TO anon;
GRANT ALL ON SEQUENCE public.usuarios_id_usuario_seq TO authenticated;
GRANT ALL ON SEQUENCE public.usuarios_id_usuario_seq TO service_role;


--
-- Name: TABLE valor; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.valor TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.valor TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.valor TO service_role;


--
-- Name: SEQUENCE valor_valor_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.valor_valor_id_seq TO anon;
GRANT ALL ON SEQUENCE public.valor_valor_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.valor_valor_id_seq TO service_role;


--
-- Name: TABLE variante_valores; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.variante_valores TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.variante_valores TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.variante_valores TO service_role;


--
-- Name: SEQUENCE variante_valores_variante_valores_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.variante_valores_variante_valores_id_seq TO anon;
GRANT ALL ON SEQUENCE public.variante_valores_variante_valores_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.variante_valores_variante_valores_id_seq TO service_role;


--
-- Name: TABLE variantes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.variantes TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.variantes TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.variantes TO service_role;


--
-- Name: SEQUENCE variantes_variante_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.variantes_variante_id_seq TO anon;
GRANT ALL ON SEQUENCE public.variantes_variante_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.variantes_variante_id_seq TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO service_role;


--
-- PostgreSQL database dump complete
--

