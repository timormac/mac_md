CREATE OR REPLACE PROCEDURE CRM_XC.PRO_SJTJ_KHCBTJ(I_MON      NUMBER,
                                                   I_YYB      NUMBER := 1,
                                                   I_REDO     NUMBER := 0,
                                                   O_RET_CODE OUT NUMBER,
                                                   O_RET_NOTE OUT VARCHAR2) AUTHID CURRENT_USER IS
    /*
    20150907  吴文华  根据老系统改造，适应信用账户表XC_DATA.TKHYDJYTJ_XY和普通账户表XC_DATA.TKHYDJYTJ
    20110926  陈枢炀  修正成本抵扣时，没有乘以汇率导致成本错误的BUG。
    20110830  陈枢炀  增加证券类别判断，收益为0的交易不计成本。
    20110117  胡长俊  由于dcuser.tKHYDJYTJ表增加了XYBZ字段,同步更改此过程;
    20101116  胡长俊  恢复成本余额时，应该恢复当月以后的累计余额，因为成本余额始终存放的是客户当前最新余额
    20100906  谢淑仁  修正抵扣计算的for循环中少group by
    20100819  谢淑仁  统计客户本身登记的总成本摊到本月客户交易统计表中（dcuser.tKHYDJYTJ），该表增加3个字段
                      alter table dcuser.tkhydjytj add cb number(16,2) default 0 not null;
                      alter table dcuser.tkhydjytj add cb_zb number(16,2) default 0 not null;
                      alter table dcuser.tkhydjytj add cb_bd number(16,2) default 0 not null;
                      COMMENT ON COLUMN DCUSER.TKHYDJYTJ.CB IS 净佣金摊占成本';
                      COMMENT ON COLUMN DCUSER.TKHYDJYTJ.CB_ZD IS '最低净佣金摊占成本';
                      COMMENT ON COLUMN DCUSER.TKHYDJYTJ.CB_BD IS '保底净佣金摊占成本';

                      tKHCBCS.CBLX字段(1|每月固定;2|周期分摊;3|佣金逐月抵扣)
    */
    V_DATETIME DATE := SYSDATE;
    V_NAME     VARCHAR2(50) := '客户自身月成本统计';
    V_PROC     VARCHAR2(50) := 'PRO_SJTJ_KHCBTJ';
    V_COUNT    NUMBER(8) := 0;
    V_KHH      NUMBER(14);
    V_JYJ      NUMBER(16, 2);
    V_KSRQ     NUMBER(8) := I_MON * 100 + 1;
    V_JSRQ     NUMBER(8) := TO_CHAR(LAST_DAY(TO_DATE(I_MON, 'yyyymm')), 'yyyymmdd');
BEGIN
    O_RET_CODE := 0;

    BEGIN
        SELECT NAME INTO V_NAME FROM TDATAJOB WHERE PROC = V_PROC;
    EXCEPTION
        WHEN OTHERS THEN
            O_RET_CODE := 0;
    END;

    --20101116  胡长俊 从最新成本余额中恢复出当月初始成本余额
    UPDATE CRMII.TKHCBCS A
       SET CBYE = CBYE + (SELECT NVL(SUM(CBJE), 0)
                            FROM CRM_XC.TKHCBLS B
                           WHERE A.ID = B.CBID
                             AND B.MON >= I_MON)
     WHERE EXISTS (SELECT 1
              FROM CRM_XC.TKHCBLS B
             WHERE A.ID = B.CBID
               AND B.MON >= I_MON);
     COMMIT;
   ---------------------
   ----以下上生产环境后恢复-HF

   ---------------------

    DELETE CRM_XC.TKHCBLS
     WHERE (I_YYB = 1 OR YYB = I_YYB)/*YYB IN
           (SELECT ID FROM CRMII.LBORGANIZATION START WITH ID = I_YYB CONNECT BY PRIOR ID = FID)*/
       AND MON = I_MON;

   ---------------------
   ----以上上生产环境后恢复-HF

   ---------------------

    --计算客户本月交易中每种类型的净佣金所摊占的成本(普通账户)
    UPDATE XC_DATA.TKHYDJYTJ
       SET CB = 0, CB_ZD = 0, CB_BD = 0,CB_A=0
     WHERE (CB > 0 OR CB_ZD > 0 OR CB_BD > 0 OR CB_A>0)
       AND MON = I_MON
       AND (I_YYB = 1 OR YYB = I_YYB)/*YYB IN
           (SELECT ID FROM CRMII.LBORGANIZATION START WITH ID = I_YYB CONNECT BY PRIOR ID = FID)*/;
    /*****************************************************************************************************************************************/
 commit;
 EXECUTE IMMEDIATE ('TRUNCATE TABLE CRMII.TEMPDATA_BB');
    INSERT INTO CRMII.TEMPDATA_BB
        (N1, C7, N3, C1, N4, N5, N6, C2, N7, C3, N8, N9, N10, N11, N12,N13)
        SELECT B.MON,
               B.TCFS,
               B.GXID,
               B.KHH,
               JYS,
               YYB,
               BZ,
               B.ZQLB ZQLB,
               WTFS,
               WTLB,
               XYBZ,
               (YJ - JYSFY - YYS) / SUM(YJ - JYSFY - YYS) OVER(PARTITION BY B.KHH,b.gxid) ZB_JYJ, --净佣金占比
               (YJ_ZD - JYSFY_ZD - YYS_ZD) / SUM(YJ - JYSFY - YYS) OVER(PARTITION BY B.KHH,b.gxid) ZB_ZDJYJ, --最低净佣金占比
               (YJ_BD - JYSFY_BD - YYS_BD) / SUM(YJ - JYSFY - YYS) OVER(PARTITION BY B.KHH,b.gxid) ZB_BDJYJ, --保底净佣金占比
               C.CBYE,
               (YJ_A - JYSFY_A - YYS_A) / SUM(YJ - JYSFY - YYS) OVER(PARTITION BY B.KHH,b.gxid) ZB_JYJ_A --净佣金占比
          FROM XC_DATA.MV_KHYDJYTJ_ALL B,
               (SELECT LPAD(KHH, /*LENGTH(KHH)*/8, '0') KHH, SUM(CBYE) CBYE
                  FROM CRMII.TKHCBCS
                 WHERE CBYE > 0
                   AND CBLX = 3
                   AND (I_YYB = 1 OR YYB = I_YYB)
                   AND KSYF <= I_MON
                   AND (JSYF >= I_MON OR JSYF IS NULL)
                 GROUP BY KHH) C,
               TZQLB D --20110830 陈枢炀 增加证券类别判断，收益为0的交易不计成本。
         WHERE B.YJ - B.JYSFY - B.YYS > 0
           AND B.KHH = C.KHH
           AND B.MON = I_MON
           AND B.ZQLB = D.ZQLB
           AND D.SYXS > 0;

           
    UPDATE XC_DATA.TKHYDJYTJ A
       SET (A.CB /*净佣金摊占成本*/,
            A.CB_ZD /*最低净佣金摊占成本*/,
            A.CB_BD /*保底净佣金摊占成本*/,
            A.CB_A) =
           (SELECT LEAST(A.YJ - A.JYSFY - A.YYS, T.N12 * T.N9),
                   LEAST(A.YJ_ZD - A.JYSFY_ZD - A.YYS_ZD, T.N12 * T.N10),
                   LEAST(A.YJ_BD - A.JYSFY_BD - A.YYS_BD, T.N12 * T.N11),
                   LEAST(A.YJ_A - A.JYSFY_A - A.YYS_A, T.N12 * T.N13)
              FROM CRMII.TEMPDATA_BB T
             WHERE A.WTLB = T.C3
               AND A.WTFS = T.N7
               AND A.ZQLB = T.C2
               AND A.YYB = T.N5
               AND A.JYS = T.N4
               AND A.KHH = T.C1
               AND A.GXID = T.N3
               AND A.XYBZ = T.N8
               AND A.MON = T.N1
                  --AND NVL(A.TCFS,0)=NVL(T.tcfs,0)
                AND NVL(A.TCFS,'0') = NVL(T.C7,'0')
               )
     WHERE EXISTS (SELECT 1
              FROM CRMII.TEMPDATA_BB T
             WHERE A.WTLB = T.C3
               AND A.WTFS = T.N7
               AND A.ZQLB = T.C2
               AND A.YYB = T.N5
               AND A.JYS = T.N4
               AND A.KHH = T.C1
               AND A.GXID = T.N3
               AND A.XYBZ = T.N8
               AND A.MON = T.N1
                  --AND NVL(A.TCFS,0)=NVL(T.tcfs,0)
               AND NVL(A.TCFS,'0') = NVL(T.C7,'0')
               )
       AND A.MON = I_MON
       AND (A.YYB = I_YYB OR I_YYB = 1)
    /*AND YYB IN (SELECT ID
    FROM LBORGANIZATION
    START WITH ID = I_YYB
    CONNECT BY PRIOR ID = FID)*/
    ;
    COMMIT;
    /*****************************************************************************************************************************************/
    --计算客户本月交易中每种类型的净佣金所摊占的成本(信用账户)
    UPDATE XC_DATA.TKHYDJYTJ_XY
       SET CB = 0, CB_ZD = 0, CB_BD = 0,CB_A=0
     WHERE (CB > 0 OR CB_ZD > 0 OR CB_BD > 0 OR CB_A>0)
       AND MON = I_MON
       AND (YYB =I_YYB OR I_YYB=1);
           --(SELECT ID FROM LBORGANIZATION START WITH ID = I_YYB CONNECT BY PRIOR ID = FID);
   -- commit;
    /*****************************************************************************************************************************************/
    UPDATE XC_DATA.TKHYDJYTJ_XY A
       SET (CB /*净佣金摊占成本*/,
            CB_ZD /*最低净佣金摊占成本*/,
            CB_BD /*保底净佣金摊占成本*/,
            CB_A) =
           (SELECT LEAST(A.YJ - A.JYSFY - A.YYS, T.N12 * T.N9),
                   LEAST(A.YJ_ZD - A.JYSFY_ZD - A.YYS_ZD, T.N12 * T.N10),
                   LEAST(A.YJ_BD - A.JYSFY_BD - A.YYS_BD, T.N12 * T.N11),
                   LEAST(A.YJ_A - A.JYSFY_A - A.YYS_A, T.N12 * T.N13)
              FROM CRMII.TEMPDATA_BB T
             WHERE A.WTLB = T.C3
               AND A.WTFS = T.N7
               AND A.ZQLB = T.C2
               AND A.YYB = T.N5
               AND A.JYS = T.N4
               AND A.KHH = T.C1
               AND A.GXID = T.N3
               AND A.XYBZ = T.N8
               AND A.MON = T.N1
                  --AND NVL(A.TCFS,0)=NVL(T.tcfs,0)
                AND NVL(A.TCFS,'0') = NVL(T.C7,'0')
               )
     WHERE EXISTS (SELECT 1
              FROM CRMII.TEMPDATA_BB T
             WHERE A.WTLB = T.C3
               AND A.WTFS = T.N7
               AND A.ZQLB = T.C2
               AND A.YYB = T.N5
               AND A.JYS = T.N4
               AND A.KHH = T.C1
               AND A.GXID = T.N3
               AND A.XYBZ = T.N8
               AND A.MON = T.N1
                  --AND NVL(A.TCFS,0)=NVL(T.tcfs,0)
                AND NVL(A.TCFS,'0') = NVL(T.C7,'0')
               )
       AND A.MON = I_MON
       AND (A.YYB = I_YYB OR I_YYB = 1)
    /*AND YYB IN (SELECT ID
    FROM LBORGANIZATION
    START WITH ID = I_YYB
    CONNECT BY PRIOR ID = FID)*/
    ;
   commit;
   ---------------------
   ----以下上生产环境后恢复-hf

   ---------------------
     --刷新物化视图
    --EXECUTE IMMEDIATE 'begin  DBMS_MVIEW.REFRESH(''XC_DATA.MV_KHYDJYTJ_ALL''); end ;';
    begin
        dbms_mview.refresh('XC_DATA.MV_KHYDJYTJ_ALL','c');
    end;

    /*****************************************************************************************************************************************/

    --对于按每月用净佣金抵扣的成本，需按照开始月份顺序抵扣，先登记的先抵扣
    --20110926 陈枢炀  增加汇率参数。
    FOR X IN (SELECT A.ID,
                     A.KHH,
                     A.KSYF,
                     MAX(A.YYB) YYB,
                     MAX(CBKM) CBKM,
                     MAX(CBYE) CBYE,
                     SUM(B.CB * NVL(C.DHBL, 1))/COUNT(DISTINCT B.GXID) DKCB
                FROM XC_DATA.MV_KHYDJYTJ_ALL B
                LEFT JOIN CRM_XC.THLCS C
                  ON B.BZ = TO_NUMBER(C.BZ)
                 AND C.KSRQ <= V_KSRQ
                 AND C.JSRQ >= V_JSRQ, CRMII.TKHCBCS A --20110926 陈枢炀 新增汇率参数
               WHERE A.CBYE > 0.0
                 AND A.CBLX = 3
                 AND B.YYB IN (SELECT ID
                                 FROM LBORGANIZATION
                                START WITH ID = I_YYB
                               CONNECT BY PRIOR ID = FID)
                 AND A.KSYF <= I_MON
                 AND (A.JSYF >= I_MON OR A.JSYF IS NULL)
                 AND B.CB > 0.0
                 AND B.KHH = LPAD(A.KHH, 8, '0')
                 AND B.MON = I_MON
               GROUP BY A.ID, A.KHH, A.KSYF
               ORDER BY A.KHH, A.KSYF, A.ID) LOOP
        IF (V_KHH IS NULL OR V_KHH != X.KHH) THEN
            V_JYJ := X.DKCB;
            V_KHH := X.KHH;
        END IF;
        IF (X.CBYE < V_JYJ) THEN
            --客户净佣金足够抵扣成本
            INSERT INTO CRM_XC.TKHCBLS
                (CBID, KHH, YYB, MON, CBKM, CBJE, CBYE)
            VALUES
                (X.ID,
                 X.KHH,
                 X.YYB,
                 I_MON,
                 X.CBKM,
                 X.CBYE,
                 X.CBYE /*此处成本余额先不减，在后边统一处理*/);
            V_JYJ   := V_JYJ - X.CBYE;
            V_COUNT := V_COUNT + 1;
        ELSIF (V_JYJ > 0) THEN
            --客户净佣金还有但不足以抵扣成本
            INSERT INTO CRM_XC.TKHCBLS
                (CBID, KHH, YYB, MON, CBKM, CBJE, CBYE)
            VALUES
                (X.ID,
                 X.KHH,
                 X.YYB,
                 I_MON,
                 X.CBKM,
                 V_JYJ,
                 X.CBYE /*此处成本余额先不减，在后边统一处理*/);
            V_JYJ   := 0;
            V_COUNT := V_COUNT + 1;
        END IF;

    END LOOP;

  COMMIT;
  
  
  /****新预处理成本统计                      **************************/
   --计算客户本月交易中每种类型的净佣金所摊占的成本(普通账户)
    UPDATE XC_DATA.TKHYDJYTJ_PZYJL
       SET CB = 0, CB_S = 0, CB_X=0
     WHERE (CB > 0 OR CB_X > 0  OR CB_S>0)
       AND MON = I_MON
       AND (I_YYB = 1 OR YYB = I_YYB)/*YYB IN
           (SELECT ID FROM CRMII.LBORGANIZATION START WITH ID = I_YYB CONNECT BY PRIOR ID = FID)*/;
    /*****************************************************************************************************************************************/
 commit;
 EXECUTE IMMEDIATE ('TRUNCATE TABLE CRMII.TEMPDATA_BB');
    INSERT INTO CRMII.TEMPDATA_BB
        (N1, C7, N3, C1, N4, N5, N6, C2, N7, C3, N8, N9, N10, N11, N12,N13)
        SELECT B.MON,
               B.TCFS,
               B.GXID,
               B.KHH,
               JYS,
               YYB,
               BZ,
               B.ZQLB ZQLB,
               WTFS,
               WTLB,
               XYBZ,
               (YJ - JYSFY - YYS) / SUM(YJ - JYSFY - YYS) OVER(PARTITION BY B.KHH,b.gxid) ZB_JYJ, --净佣金占比
               (YJ_X - JYSFY_X - YYS_X) / SUM(YJ - JYSFY - YYS) OVER(PARTITION BY B.KHH,b.gxid) ZB_JYJ_X, --万2.5以下净佣金占比
               NULL,--(YJ_X_S - JYSFY_X_S - YYS_X_S) / SUM(YJ - JYSFY - YYS) OVER(PARTITION BY B.KHH,b.gxid) ZB_JYJ_X_S, --万2.5-万3净佣金占比
               (YJ_S - JYSFY_S - YYS_S) / SUM(YJ - JYSFY - YYS) OVER(PARTITION BY B.KHH,b.gxid) ZB_JYJ_S, --万3以上净佣金占比
               C.CBYE
          FROM XC_DATA.MV_KHYDJYTJ_ALL_PZYJL B,
               (SELECT LPAD(KHH, /*LENGTH(KHH)*/8, '0') KHH, SUM(CBYE) CBYE
                  FROM CRMII.TKHCBCS
                 WHERE CBYE > 0
                   AND CBLX = 3
                   AND (I_YYB = 1 OR YYB = I_YYB)
                   AND KSYF <= I_MON
                   AND (JSYF >= I_MON OR JSYF IS NULL)
                 GROUP BY KHH) C,
               TZQLB D --20110830 陈枢炀 增加证券类别判断，收益为0的交易不计成本。
         WHERE B.YJ - B.JYSFY - B.YYS > 0
           AND B.KHH = C.KHH
           AND B.MON = I_MON
           AND B.ZQLB = D.ZQLB
           AND D.SYXS > 0;
    UPDATE XC_DATA.TKHYDJYTJ_PZYJL A
       SET (A.CB /*净佣金摊占成本*/,
            A.CB_X /*万2.5净佣金摊占成本*/,
            --A.CB_X_S /*万2.5-万3净佣金摊占成本*/,
            A.CB_S /*万3净佣金摊占成本*/) =
           (SELECT LEAST(A.YJ - A.JYSFY - A.YYS, T.N13 * T.N9),
                   LEAST(A.YJ_X - A.JYSFY_X - A.YYS_X, T.N13 * T.N10),
                  -- LEAST(A.YJ_X_S - A.JYSFY_X_S - A.YYS_X_S, T.N13 * T.N11),
                   LEAST(A.YJ_S - A.JYSFY_S - A.YYS_S, T.N13 * T.N12)
              FROM CRMII.TEMPDATA_BB T
             WHERE A.WTLB = T.C3
               AND A.WTFS = T.N7
               AND A.ZQLB = T.C2
               AND A.YYB = T.N5
               AND A.JYS = T.N4
               AND A.KHH = T.C1
               AND A.GXID = T.N3
               AND A.XYBZ = T.N8
               AND A.MON = T.N1
                  --AND NVL(A.TCFS,0)=NVL(T.tcfs,0)
                AND NVL(A.TCFS,'0') = NVL(T.C7,'0')
               )
     WHERE EXISTS (SELECT 1
              FROM CRMII.TEMPDATA_BB T
             WHERE A.WTLB = T.C3
               AND A.WTFS = T.N7
               AND A.ZQLB = T.C2
               AND A.YYB = T.N5
               AND A.JYS = T.N4
               AND A.KHH = T.C1
               AND A.GXID = T.N3
               AND A.XYBZ = T.N8
               AND A.MON = T.N1
                  --AND NVL(A.TCFS,0)=NVL(T.tcfs,0)
               AND NVL(A.TCFS,'0') = NVL(T.C7,'0')
               )
       AND A.MON = I_MON
       AND (A.YYB = I_YYB OR I_YYB = 1)
   
    ;
    COMMIT;
    /*****************************************************************************************************************************************/
    --计算客户本月交易中每种类型的净佣金所摊占的成本(信用账户)
    UPDATE XC_DATA.TKHYDJYTJ_XY_PZYJL
       SET CB = 0, CB_X = 0,/* CB_X_S = 0,*/CB_S=0
     WHERE (CB > 0 OR CB_X > 0 /*OR CB_X_S > 0 */OR CB_S=0)
       AND MON = I_MON
       AND (YYB =I_YYB OR I_YYB=1);
           --(SELECT ID FROM LBORGANIZATION START WITH ID = I_YYB CONNECT BY PRIOR ID = FID);
   -- commit;
    /*****************************************************************************************************************************************/
    UPDATE XC_DATA.TKHYDJYTJ_XY_PZYJL A
       SET (CB /*净佣金摊占成本*/,
            CB_X /*万2.5净佣金摊占成本*/,
            --CB_X_S /*万2.5-万3净佣金摊占成本*/,
            CB_S /*万3净佣金摊占成本*/) =
           (SELECT LEAST(A.YJ - A.JYSFY - A.YYS, T.N13 * T.N9),
                   LEAST(A.YJ_X - A.JYSFY_X - A.YYS_X, T.N13 * T.N10),
                   --LEAST(A.YJ_X_S - A.JYSFY_X_S - A.YYS_X_S, T.N13 * T.N11),
                   LEAST(A.YJ_S - A.JYSFY_S - A.YYS_S, T.N13 * T.N12)
              FROM CRMII.TEMPDATA_BB T
             WHERE A.WTLB = T.C3
               AND A.WTFS = T.N7
               AND A.ZQLB = T.C2
               AND A.YYB = T.N5
               AND A.JYS = T.N4
               AND A.KHH = T.C1
               AND A.GXID = T.N3
               AND A.XYBZ = T.N8
               AND A.MON = T.N1
                  --AND NVL(A.TCFS,0)=NVL(T.tcfs,0)
                AND NVL(A.TCFS,'0') = NVL(T.C7,'0')
               )
     WHERE EXISTS (SELECT 1
              FROM CRMII.TEMPDATA_BB T
             WHERE A.WTLB = T.C3
               AND A.WTFS = T.N7
               AND A.ZQLB = T.C2
               AND A.YYB = T.N5
               AND A.JYS = T.N4
               AND A.KHH = T.C1
               AND A.GXID = T.N3
               AND A.XYBZ = T.N8
               AND A.MON = T.N1
                  --AND NVL(A.TCFS,0)=NVL(T.tcfs,0)
                AND NVL(A.TCFS,'0') = NVL(T.C7,'0')
               )
       AND A.MON = I_MON
       AND (A.YYB = I_YYB OR I_YYB = 1)
    /*AND YYB IN (SELECT ID
    FROM LBORGANIZATION
    START WITH ID = I_YYB
    CONNECT BY PRIOR ID = FID)*/
    ;
   commit;
   ---------------------
   ----以下上生产环境后恢复-hf

   ---------------------
     --刷新物化视图
    --EXECUTE IMMEDIATE 'begin  DBMS_MVIEW.REFRESH(''XC_DATA.MV_KHYDJYTJ_ALL''); end ;';
    begin
        dbms_mview.refresh('XC_DATA.MV_KHYDJYTJ_ALL_PZYJL','c');
    end;

    /*****************************************************************************************************************************************/

    --对于按每月用净佣金抵扣的成本，需按照开始月份顺序抵扣，先登记的先抵扣
    --20110926 陈枢炀  增加汇率参数。
    FOR X IN (SELECT A.ID,
                     A.KHH,
                     A.KSYF,
                     MAX(A.YYB) YYB,
                     MAX(CBKM) CBKM,
                     MAX(CBYE) CBYE,
                     SUM(B.CB * NVL(C.DHBL, 1))/COUNT(DISTINCT B.GXID) DKCB
                FROM XC_DATA.MV_KHYDJYTJ_ALL_PZYJL B
                LEFT JOIN CRM_XC.THLCS C
                  ON B.BZ = TO_NUMBER(C.BZ)
                 AND C.KSRQ <= V_KSRQ
                 AND C.JSRQ >= V_JSRQ, CRMII.TKHCBCS A --20110926 陈枢炀 新增汇率参数
               WHERE A.CBYE > 0.0
                 AND A.CBLX = 3
                 AND B.YYB IN (SELECT ID
                                 FROM LBORGANIZATION
                                START WITH ID = I_YYB
                               CONNECT BY PRIOR ID = FID)
                 AND A.KSYF <= I_MON
                 AND (A.JSYF >= I_MON OR A.JSYF IS NULL)
                 AND B.CB > 0.0
                 AND B.KHH = LPAD(A.KHH, 8, '0')
                 AND B.MON = I_MON
               GROUP BY A.ID, A.KHH, A.KSYF
               ORDER BY A.KHH, A.KSYF, A.ID) LOOP
        IF (V_KHH IS NULL OR V_KHH != X.KHH) THEN
            V_JYJ := X.DKCB;
            V_KHH := X.KHH;
        END IF;
        IF (X.CBYE < V_JYJ) THEN
            --客户净佣金足够抵扣成本
            INSERT INTO CRM_XC.TKHCBLS
                (CBID, KHH, YYB, MON, CBKM, CBJE, CBYE)
            VALUES
                (X.ID,
                 X.KHH,
                 X.YYB,
                 I_MON,
                 X.CBKM,
                 X.CBYE,
                 X.CBYE /*此处成本余额先不减，在后边统一处理*/);
            V_JYJ   := V_JYJ - X.CBYE;
            V_COUNT := V_COUNT + 1;
        ELSIF (V_JYJ > 0) THEN
            --客户净佣金还有但不足以抵扣成本
            INSERT INTO CRM_XC.TKHCBLS
                (CBID, KHH, YYB, MON, CBKM, CBJE, CBYE)
            VALUES
                (X.ID,
                 X.KHH,
                 X.YYB,
                 I_MON,
                 X.CBKM,
                 V_JYJ,
                 X.CBYE /*此处成本余额先不减，在后边统一处理*/);
            V_JYJ   := 0;
            V_COUNT := V_COUNT + 1;
        END IF;


    END LOOP;

  COMMIT;
  
  /******  新增处理结束                                 *************************/
  
    --对于按月均摊和一次性成本可批量生成成本流水
    INSERT INTO CRM_XC.TKHCBLS
        (CBID, KHH, YYB, MON, CBKM, CBJE, CBYE)
        SELECT A.ID,
               A.KHH,
               A.YYB,
               I_MON,
               CBKM,
               CASE
                   WHEN CBLX = 2 /*每月均摊*/
                    THEN
                    CBYE /
                    (MONTHS_BETWEEN(TO_DATE(JSYF, 'yyyymm'), TO_DATE(I_MON, 'yyyymm')) + 1)
                   ELSE /*一次性*/
                    CBJE
               END,
               CBYE
          FROM CRMII.TKHCBCS A
         WHERE A.CBYE > 0.0
           AND A.CBLX IN (1, 2)
           AND A.YYB IN (SELECT ID
                           FROM LBORGANIZATION
                          START WITH ID = I_YYB
                         CONNECT BY PRIOR ID = FID)
           AND A.KSYF <= I_MON
           AND (A.JSYF >= I_MON OR A.JSYF IS NULL);

    V_COUNT := V_COUNT + SQL%ROWCOUNT;
    COMMIT;

    --批量更正成本流水中的本次成本余额
    UPDATE CRM_XC.TKHCBLS
       SET CBYE = CBYE - CBJE
     WHERE (I_YYB = 1 OR YYB = I_YYB)
       AND MON = I_MON
       AND YYB IN
           (SELECT ID FROM LBORGANIZATION START WITH ID = I_YYB CONNECT BY PRIOR ID = FID);
      COMMIT;

   
    --20101116  胡长俊 将当前成本余额恢复至最新余额状态
    UPDATE CRMII.TKHCBCS A
       SET CBYE =
           (SELECT A.CBJE - SUM(B.CBJE)
              FROM CRM_XC.TKHCBLS B
             WHERE (I_YYB = 1 OR B.YYB = I_YYB)
               AND A.ID = B.CBID
               )
     WHERE EXISTS (SELECT 1
              FROM CRM_XC.TKHCBLS B
             WHERE(I_YYB = 1 OR B.YYB = I_YYB)
               AND A.ID = B.CBID
               AND B.MON >= I_MON
               );
       ---------------------
   ----以上上生产环境后恢复-HF

   ---------------------
 COMMIT;
    PRO_WRITELOG(1,
                 V_NAME,
                 V_PROC || '(' || I_MON || ',' || NVL(TO_CHAR(I_YYB), 'null') || ',' || 1 ||
                 ',o_code,o_note)',
                 0,
                 '执行成功[记录:' || V_COUNT || '],用时' ||
                 TRUNC((SYSDATE - V_DATETIME) * 1440.00 * 60) || '秒',
                 V_COUNT,
                 TRUNC((SYSDATE - V_DATETIME) * 1440.00 * 60));
    COMMIT;
    --刷新物化视图
    --EXECUTE IMMEDIATE 'begin  DBMS_MVIEW.REFRESH(''XC_DATA.MV_KHYDJYTJ_ALL''); end ;';
    begin
        dbms_mview.refresh('XC_DATA.MV_KHYDJYTJ_ALL','c');
    end;
    
    --刷新物化视图
    --EXECUTE IMMEDIATE 'begin  DBMS_MVIEW.REFRESH(''XC_DATA.MV_KHYDJYTJ_ALL''); end ;';
    begin
        dbms_mview.refresh('XC_DATA.MV_KHYDJYTJ_ALL_PZYJL','c');
    end;

    O_RET_CODE := 1;
    O_RET_NOTE := '成功';
EXCEPTION
    WHEN OTHERS THEN
        O_RET_CODE := -1;
        O_RET_NOTE := V_PROC || '执行错误:' || SQLERRM;
        ROLLBACK;
        PRO_WRITELOG(1,
                     V_NAME,
                     V_PROC || '(' || I_MON || ',' || NVL(TO_CHAR(I_YYB), 'null') || ',' || 1 ||
                     ',o_code,o_note)',
                     2,
                     O_RET_NOTE);
END PRO_SJTJ_KHCBTJ;

 
