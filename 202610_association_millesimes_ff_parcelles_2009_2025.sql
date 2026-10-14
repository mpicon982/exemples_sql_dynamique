DO LANGUAGE plpgsql
$$
    declare v_annees1 text;
            v_annees2  text;
            v_dep text;
            v_schema text;
            v_table text;
            v_rqt_part1 text:='';
            v_rqt_part2 text:='';
            v_rqt_complete text;
            v_unionall text:='';
        begin
        for v_annees1,v_dep in
        select
        a::text,
        dep
        from
            generate_series(2009,2017) as gs(a),
            lateral (values ('54'),('55'),('88')) as l(dep)
        where a!=2010
        loop
        --gestion des union all sauf pour premier élément de requête
        if v_rqt_part1!='' then v_unionall:=' union all '; end if;
        --création propre des ident sql
        v_schema:=format($a$ff_d%s_%s$a$,v_dep,v_annees1);
        v_table:=format($a$d%s_%s_pnb10_parcelle$a$,v_dep,v_annees1);
        v_rqt_part1:=v_rqt_part1||v_unionall||format($a$
        select %L millesime, idcom, idpar, ccosec, dnupla, st_transform(geompar,2154) geompar from %I.%I
                $a$,v_annees1,v_schema,v_table);
        end loop;
        --contrôle
    --raise notice '%',v_rqt_part1;
        for v_annees2, v_dep in
            select
            a::text,
            dep
                from generate_series(2018,2024) g(a),
                     lateral (values ('54'),('55'),('88')) l(dep)
            loop
            -- v_unionall déjà affecté par la boucle 1, volontairement non réinitialisé
            --creéation propre des identifiants sql
            v_schema:=format($a$ff_%s_dep$a$,v_annees2);
            v_table:=format($a$d%s_fftp_%s_pnb10_parcelle$a$,v_dep,v_annees2);
            v_rqt_part2:=v_rqt_part2||v_unionall||format($a$
        select %L millesime, idcom, idpar, ccosec, dnupla, st_transform(geompar,2154) geompar from %I.%I
                $a$,v_annees2,v_schema,v_table);
            end loop;
        --execution rqt_finale
       v_rqt_complete:='create view ff.v_ff2009_2025_parcelles as('||v_rqt_part1||v_rqt_part2||$a$ union all select '2025', idcom, idpar, ccosec, dnupla, st_transform(geompar,2154) from ff_2025.fftp_2025_pnb10_parcelle where ccodep in ('54','55','88'));$a$;
        --contrôle
        --raise notice '%',v_rqt_complete;
        drop view if exists ff.v_ff2009_2025_parcelles;
        execute v_rqt_complete;
        end
$$;
