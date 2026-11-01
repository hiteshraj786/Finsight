$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Open("c:\Users\hites\OneDrive\Desktop\finsight\finsight-design-doc.docx")
$doc.SaveAs("c:\Users\hites\OneDrive\Desktop\finsight\finsight-design-doc.txt", 2)
$doc.Close(0)
$word.Quit(0)
