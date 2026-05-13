# Estructura base de auditoría

## Propósito

Todas las tablas del sistema hotelero comparten un conjunto de columnas comunes que permiten auditar el ciclo de vida completo de cada registro: quién lo creó, quién lo modificó y quién lo eliminó lógicamente. Esta convención se aplica **antes** de crear cualquier tabla de negocio y es transversal a los 8 módulos funcionales del sistema.

---

## Campos de auditoría

| Campo | Tipo | Valor por defecto | Nulos | Descripción |
|---|---|---|---|---|
| `id` | `UUID` | `gen_random_uuid()` | No | Llave primaria única de cada registro. Se genera automáticamente. |
| `created_by` | `UUID` | — | Sí | Identificador del usuario que creó el registro. |
| `created_at` | `TIMESTAMP` | `NOW()` | No | Fecha y hora exacta de creación del registro. |
| `updated_by` | `UUID` | — | Sí | Identificador del usuario que realizó la última modificación. |
| `updated_at` | `TIMESTAMP` | — | Sí | Fecha y hora de la última modificación. Se mantiene automáticamente mediante el trigger `set_updated_at()`. |
| `deleted_by` | `UUID` | — | Sí | Identificador del usuario que realizó la eliminación lógica. |
| `deleted_at` | `TIMESTAMP` | — | Sí | Fecha y hora en que el registro fue eliminado lógicamente. |
| `status` | `VARCHAR(30)` | `'ACTIVE'` | No | Estado actual del registro. Permite la eliminación lógica sin borrar datos físicamente. |

---

## Valores del campo `status`

| Valor | Descripción |
|---|---|
| `ACTIVE` | Registro activo y visible en operaciones normales. |
| `INACTIVE` | Registro desactivado pero conservado en la base de datos. |
| `DELETED` | Registro eliminado lógicamente. No se borra físicamente. |

---

## Eliminación lógica

El sistema **no elimina registros físicamente**. Cuando un registro se da de baja, se actualiza `status = 'DELETED'`, se registra `deleted_at = NOW()` y se asigna el `deleted_by` con el UUID del usuario que ejecutó la acción. Esto garantiza trazabilidad completa e historial auditable.

---

## Trigger `set_updated_at()`

El campo `updated_at` no se actualiza manualmente. Cada tabla tiene un trigger asociado a la función `set_updated_at()` que se dispara automáticamente en cada operación `UPDATE`, asegurando que el campo siempre refleje la hora real de la última modificación.

```sql
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## Ejemplo de aplicación

```sql
CREATE TABLE parameterization.customer (
  id           UUID          DEFAULT gen_random_uuid() PRIMARY KEY,
  -- campos propios de la tabla
  name         VARCHAR(100)  NOT NULL,
  email        VARCHAR(150)  NOT NULL,
  -- auditoría
  created_by   UUID,
  created_at   TIMESTAMP     DEFAULT NOW() NOT NULL,
  updated_by   UUID,
  updated_at   TIMESTAMP,
  deleted_by   UUID,
  deleted_at   TIMESTAMP,
  status       VARCHAR(30)   DEFAULT 'ACTIVE' NOT NULL
);

CREATE TRIGGER trg_customer_updated_at
BEFORE UPDATE ON parameterization.customer
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

---

## Nota

Esta estructura aplica a las **48 tablas** distribuidas en los 8 schemas funcionales del sistema (`parameterization`, `distribution`, `service_delivery`, `billing`, `inventory`, `notification`, `security`, `maintenance`). Ninguna tabla de negocio se crea sin estos campos.
