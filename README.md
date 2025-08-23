# oci-cloudguard

[0] 前提条件
1. OCI tenancy(Administrators)権限を有するaccountでコンソールログインできること
2. サンプルプログラム１のみpythonを実行できる環境が必要

*OCI CLIがtenancy権限で実行できる環境であれば可能ですが、この場合は各シェルの最初で、
Tenancy OCIDをCloud shell環境変数から取得するところをコメントアウトして
代わりにTENANCY_OCIDを直接入力ください。

[1] サンプルプログラム１:Cloud Guard 監査レポート出力プログラム

概要:
OCI全体のセキュリティ遵守状況を可視化した監査レポート(MS WORD文書)の出力

関連シェル、プログラムなど:
1.oci-cloud-guard-check.sh:   Cloud GuardのConfiguration情報取得シェル
2.generate_rof_10.py:        Cloud Guard監査サマリ作成プログラム
3.generate_problem_details_doc_5.py: Cloud Guard監査詳細作成プログラム
4.OCI_Security_Health_Check_Report_Sample_v2.pdf :サンプル結果

手順：
1. 自身のPCにoci-cloud-guard-check.sh、generate_rof_10.py、generate_problem_details_doc_5.pyをダウンロード
2. tenancy(Administrators)権限にてOCI Console login後OCI Cloud Shellを開く
3. Cloud Shellのメニューからoci-cloud-guard-check.shをupload
4. oci-cloud-guard-check.sh を実行
  $ chmod +x oci-cloud-guard-check.sh
  $ ./oci-cloud-guard-check.sh 
  "CGAudit_実行日時"の名前のDirectoryが新規に作成され以下にCloud Guardの各種Configuration関連fileが作成される
5.上記Directory自体のzipも作成されるのでCloud Shellのメニューから自PCにDownload
6.自PCで上記zipを解凍: Cloud Shell上でシェル実行した結果の"CGAudit_実行日時"の名前のDirectoryが展開される
7. すでにDownloadしてあるgenerate_rof_10.py、generate_problem_details_doc_5.pyを上記Directory下にコピー
8. python仮想環境作成
   $ python3 -m venv myenv
9. (myenv)仮想環境へ移動してword library導入、python 実行
  $ source myenv/bin/activate
  $ pip install python-docx
  $ python3 generate_rof_10.py
  $ python3 generate_problem_details_doc_5.py
  $ deactivate
10. 結果Directory下にword文書が作成
  Detector_Recipes_Compliance_Status.dox
  Problem_Details_Report.docx

[2]サンプルプログラム2: Cloud Guard Recipe構成設定出力

概要:
Cloud Guard設計/カストマイズ用にレシピ構成設定内容の一覧を出力

関連シェル、プログラムなど:
Recipe_rules.sh:　Recipe構成出力シェル
IAAS_CONFIGURATION_DETECTOR_RecipeConfig.csv: サンプル結果 

手順:
1. 自PCにRecipe_rules.shをダウンロード

2. tenancy(Administrators)権限にてOCI Console login後OCI Cloud Shellを開く

3. Cloud ShellのメニューからRecipe_rules.shをupload

4. Recipe_rules.sh実行
$ chmod +x Recipe_rules.sh
$ ./Recipe_rules.sh

5. "RecipeConfig_実行日時"の名前のDirectoryが新規に作成され配下にCloud Guardの各種Recipe構成file(Detectorタイプ単位)が作成される。必要に応じてCloud Shellのメニューから自PCにダウンロード

[3]サンプルプログラム3: Cloud Guard全Problems一覧出力

概要:
Cloud Guard運用者向けに全ての問題の一覧(問題詳細/対応案含)を出力

関連シェル、プログラムなど:
Recipe_Rules_recommend.sh　:Problem一覧出力シェル
IAAS_CONFIGURATION_DETECTOR_ProblemList.csv　:サンプル結果

手順:
1. 自PCにRecipe_Rules_recommend.shをダウンロード

2. tenancy(Administrators)権限にてOCI Console login後OCI Cloud Shellを開く

3. Cloud ShellのメニューからRecipe_Rules_recommend.shをupload

4. Recipe_Rules_recommend.sh実行
$ chmod +x Recipe_Rules_recommend.sh
$ ./Recipe_Rules_recommend.sh


5. "ProblemList_実行日時"の名前のDirectoryが新規に作成され配下にCloud GuardのProblem File(Detectorタイプ単位)を作成される。必要に応じてCloud Shellのメニューから自PCにダウンロード


