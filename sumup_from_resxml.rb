# encoding: utf-8

require 'uri'
require 'open-uri'
require 'rexml/document'
require 'kconv'
require 'csv'

# **************************************************************
# 調査種別の表記ゆれを解消するメソッド
# 引数　：　res_type(調査種別の文字列)
# 返り値：　restype_arr(調査種別の配列)
def split_restype(restype)
  restype.chomp!
  # 区切り文字として使用されているもので分割して配列として返す
  # 区切り文字としての使用を確認できた文字
  #   ⇒「空白」, 「，（全角コンマ）」, 「・（中黒）」, 「?」, 「＆」, 「、」, 「;」, 「および」
  restype_arr = restype.split(/[　 ，・;＆、\?]|(および)/)
  # 空文字を消去
  restype_arr.delete_if{|e| "" == e}.compact!
  return restype_arr
end

# *************************************************************



# *****REXMLを用いてそれぞれの要素ごとに取り出す*****

refakyoudata = Hash.new #結果出力用のハッシュを用意

# ━━━━━━━━━━━━━━━━━━━━━━━━━
#　　　　　　　    取り出し可能項目一覧
# ━━━━━━━━━━━━━━━━━━━━━━━━━
# sys_id      数値
# question    質問
# solution    解決・未解決のフラグ
#             半角数値 解決 1 未解決 2
# crt_data    事例作成日
# ndc_class   NDC番号
# restype_arr 調査種別
# ptn-type    質問者区分 - 
# 「未就学児」「小中学生」「高校生」「学生」「社会人」「団体」「図書館」または任意の文字列
# lib-name    図書館名（回答）

file_path_of_xml = "response_xml.xml"

doc = REXML::Document.new(File.read(file_path_of_xml))
doc.elements.each('result_set/result') do |element|

  # システムID登録番号をsys_idに代入
  sys_id = element.elements['reference/system/sys-id'].text

  # 質問をquestionに代入
  question = element.elements['reference/question'].text
  .gsub("\n", " ").gsub("\"", "”").gsub("\t","  ")
  #question = "\"" + question + "\""

  # 解決/未解決をsolに代入
  if element.elements['reference/solution'].nil?
    solution = "None"
  else
    solution = element.elements['reference/solution'].text
  end
  
  # 事例作成日のデータが入っていない場合があるので、そのときは0000にしておく
  if element.elements['reference/crt-date'].nil?
    crt_data = "None"
  else
    crt_data = element.elements['reference/crt-date'].text
    crt_data = crt_data[0,4]
  end

  # 分類番号をnumber_classに代入
  number_class = []
  if element.elements['reference/class'].nil?
    number_class = ["None"]
  else
    element.elements.each do |e2|
      e2.elements.each('class') do |e3|
        ndc_str = e3.text
        number_class.push(ndc_str)
      end
    end
  end
  number_class.join("-")

  # 図書館名をlib_nameに代入
  if element.elements['reference/system/lib-name'].nil?
    lib_name = "None"
  else
    lib_name = element.elements['reference/system/lib-name'].text
  end

  # 調査種別をres_typeに代入
  if element.elements['reference/res-type'].nil?
    restype_arr = ["None"]
  else
    res_type = element.elements['reference/res-type'].text.gsub("\"", "”")
    #調査種別をrestype_arrに代入
    restype_arr = split_restype(res_type)
  end
  reftype = restype_arr.join("―")

  # 質問者区分
  if element.elements['reference/ptn-type'].nil?
    ptn_type = "None"
  else
    ptn_type = element.elements['reference/ptn-type'].text
    #ptn_type = "\"" + ptn_type + "\""
  end

  # 結果の配列
  results = [question, solution, crt_data, number_class, reftype, ptn_type, lib_name]
  #print(results.join(","), "\n")


  # データをハッシュrefakyoudataに登録
  # key    ：　システムID
  # valuele： [ID, 質問, 解決・未解決, 事例作成日, NDC番号, 調査種別, 質問者区分, 図書館名]
  refakyoudata[sys_id] = results
end

# 結果の出力
refakyoudata.each{|key, value| puts("#{key}:#{value.join(",")}") }
