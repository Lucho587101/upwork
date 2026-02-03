prompt
prompt package: fd_quiec_pag
prompt
create or replace package fd_quiec_pag as
--
-- #VERSION:00000000003
--
-- Historial de cambios
--
-- Versión     Solicitud        Fecha        Realizó        Comentario
-- =========== ================ ============ ============== =============================================================================================================
-- 0001        null              16/10/2025  L.ponton        Paquete principal que gestiona operaciones de usuarios, estudiantes, cursos e inscripciones
-- 0002        null              17/10/2025  L.ponton        Se agregan parámetros de respuesta (p_rpta_cod, p_rpta_msg)
-- 0003        null              18/10/2025  L.ponton        Se ajusta inscripción para manejar nombre del estudiante en lugar de ID
-- =========== ================ ============ ============== =============================================================================================================
--

  -- manejo de usuarios
  procedure p_ins_usuario(
       p_user      in varchar2
      ,p_pass      in varchar2
      ,p_rol       in varchar2
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  );

  -- manejo de estudiantes
  procedure p_ins_estudiante(
       p_nombre    in varchar2
      ,p_email     in varchar2
      ,p_fnac      in date
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  );

  -- manejo de cursos
  procedure p_ins_curso(
       p_nombre    in varchar2
      ,p_creditos  in number
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  );

  -- manejo de inscripciones
  procedure p_ins_inscripcion(
       p_nom_estu  in varchar2
      ,p_curs_id   in number
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  );

  procedure p_upd_inscripcion(
       p_id        in number
      ,p_nom_estu  in varchar2
      ,p_curs_id   in number
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  );

  procedure p_del_inscripcion(
       p_id        in number
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  );

end fd_quiec_pag;
/
show errors
/

-- #VERSION:00000000003
-- creado por l.ponton

create or replace package body fd_quiec_pag as

  -- Inserta usuario validando duplicados y rol permitido
  procedure p_ins_usuario(
       p_user      in varchar2
      ,p_pass      in varchar2
      ,p_rol       in varchar2
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  ) is
    v_existe number;
  begin
    select count(*)
      into v_existe
      from fd_tusua
     where usua_user = trim(p_user);

    if v_existe > 0 then
       p_rpta_cod := 'ERR';
       p_rpta_msg := 'El usuario ya existe (sin distinguir mayúsculas/minúsculas)';
       return;
    end if;

    if upper(p_rol) not in ('ADMIN', 'EST') then
       p_rpta_cod := 'ERR';
       p_rpta_msg := 'Rol inválido: solo ADMIN o EST';
       return;
    end if;

    insert into fd_tusua (
         usua_id
        ,usua_user
        ,usua_pass
        ,usua_rol
    )
    values (
         fd_susua.nextval
        ,lower(trim(p_user))
        ,p_pass
        ,upper(trim(p_rol))
    );

    commit;
    p_rpta_cod := 'OK';
    p_rpta_msg := 'Usuario insertado correctamente';
  exception
    when others then
      p_rpta_cod := 'ERR';
      p_rpta_msg := 'Error inesperado en p_ins_usuario: ' || sqlerrm;
  end p_ins_usuario;



  -- Inserta estudiante
  procedure p_ins_estudiante(
       p_nombre    in varchar2
      ,p_email     in varchar2
      ,p_fnac      in date
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  ) is
  begin
    insert into fd_testu (
         estu_id
        ,estu_nombre
        ,estu_email
        ,estu_fnac
    )
    values (
         fd_sestu.nextval
        ,initcap(p_nombre)
        ,lower(p_email)
        ,p_fnac
    );

    commit;
    p_rpta_cod := 'OK';
    p_rpta_msg := 'Estudiante insertado correctamente';
  exception
    when others then
      p_rpta_cod := 'ERR';
      p_rpta_msg := 'Error inesperado en p_ins_estudiante: ' || sqlerrm;
  end p_ins_estudiante;



  -- Inserta curso validando duplicado
  procedure p_ins_curso(
       p_nombre    in varchar2
      ,p_creditos  in number
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  ) is
    v_existe number;
  begin
    select count(*)
      into v_existe
      from fd_tcurs
     where lower(curs_nombre) = lower(p_nombre)
       and curs_creditos = p_creditos;

    if v_existe > 0 then
       p_rpta_cod := 'ERR';
       p_rpta_msg := 'Curso duplicado';
       return;
    end if;

    insert into fd_tcurs (
         curs_id
        ,curs_nombre
        ,curs_creditos
    )
    values (
         fd_scurs.nextval
        ,initcap(p_nombre)
        ,p_creditos
    );

    commit;
    p_rpta_cod := 'OK';
    p_rpta_msg := 'Curso insertado correctamente';
  exception
    when others then
      p_rpta_cod := 'ERR';
      p_rpta_msg := 'Error inesperado en p_ins_curso: ' || sqlerrm;
  end p_ins_curso;



  -- Inserta inscripción validando duplicado estudiante+curso 
  procedure p_ins_inscripcion(
       p_nom_estu  in varchar2
      ,p_curs_id   in number
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  ) is
    v_existe_estu number;
    v_existe_insc number;
  begin
    select count(*)
      into v_existe_estu
      from fd_testu
     where lower(estu_nombre) = lower(p_nom_estu);

    if v_existe_estu = 0 then
      p_rpta_cod := 'ERR';
      p_rpta_msg := 'El estudiante no existe en la base de datos';
      return;
    end if;

    select count(*)
      into v_existe_insc
      from fd_tinsc
     where lower(insc_nom_estu) = lower(p_nom_estu)
       and insc_curs_id = p_curs_id;

    if v_existe_insc > 0 then
      p_rpta_cod := 'ERR';
      p_rpta_msg := 'El estudiante ya está inscrito en este curso';
      return;
    end if;

    insert into fd_tinsc (
         insc_id
        ,insc_nom_estu
        ,insc_curs_id
        ,insc_fecha
    )
    values (
         fd_sinsc.nextval
        ,initcap(p_nom_estu)
        ,p_curs_id
        ,sysdate
    );

    commit;
    p_rpta_cod := 'OK';
    p_rpta_msg := 'Inscripción registrada correctamente';
  exception
    when others then
      p_rpta_cod := 'ERR';
      p_rpta_msg := 'Error inesperado en p_ins_inscripcion: ' || sqlerrm;
  end p_ins_inscripcion;



  -- Actualiza inscripción
  procedure p_upd_inscripcion(
       p_id        in number
      ,p_nom_estu  in varchar2
      ,p_curs_id   in number
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  ) is
  begin
    update fd_tinsc
       set insc_nom_estu = initcap(p_nom_estu)
          ,insc_curs_id = p_curs_id
          ,insc_fecha   = sysdate
     where insc_id = p_id;

    if sql%rowcount = 0 then
       p_rpta_cod := 'ERR';
       p_rpta_msg := 'No existe inscripción con ese ID';
       return;
    end if;

    commit;
    p_rpta_cod := 'OK';
    p_rpta_msg := 'Inscripción actualizada correctamente';
  exception
    when others then
      p_rpta_cod := 'ERR';
      p_rpta_msg := 'Error inesperado en p_upd_inscripcion: ' || sqlerrm;
  end p_upd_inscripcion;



  -- Elimina inscripción
  procedure p_del_inscripcion(
       p_id        in number
      ,p_rpta_cod  out varchar2
      ,p_rpta_msg  out varchar2
  ) is
  begin
    delete from fd_tinsc
     where insc_id = p_id;

    if sql%rowcount = 0 then
       p_rpta_cod := 'ERR';
       p_rpta_msg := 'No existe inscripción con ese ID';
       return;
    end if;

    commit;
    p_rpta_cod := 'OK';
    p_rpta_msg := 'Inscripción eliminada correctamente';
  exception
    when others then
      p_rpta_cod := 'ERR';
      p_rpta_msg := 'Error inesperado en p_del_inscripcion: ' || sqlerrm;
  end p_del_inscripcion;

end fd_quiec_pag;
/
show errors
/