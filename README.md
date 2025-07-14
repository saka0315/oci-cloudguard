# oci-cloudguard
shell&amp;python program for making security report  by using oci-cloudguard 

OCI Cloud Gurad Recipeなどの構成情報を抽出してMS-Word/Excelに出力するCodeを開発する際、AWSと違いOCI SDKの戻り値（Response.data）がネストされたクラスオブジェクトのリスト形式になっており、JSON-likeなdict形式にするにはto_dict()メソッドのような明示的な変換処理が必要となり煩雑です、この点CLIの方がSDKよりOCI構成取得処理はシンプルで早い、構成情報の全体像を簡単に把握できる、メンテナンス容易におこなえる、そもそもが学習用サンプルプログラムであることから、OCI SDKで全てをCodeすることは避け、まずはOCI CLI で必要な情報をJSONやCSVに抽出、必要に応じてjq加工処理、ここまではshell化して、最後にpython codeでJSON/CSVからMS-Word/Excelに変換しています。


