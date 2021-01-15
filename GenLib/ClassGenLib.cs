using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GenLib
{
    public class ClassGenLib
    {
        public static string selectedClient;
        public static int closeLog = 0;
        public static string username;


        public static int selectedComponent;
        public static string ServerIP;
        public static int dataImportThreadFinished = 0;
        //public static string Encrypt(string textToHide)

        public static string HashPass(string szPlainText, int szEncryptionKey)
        {
            StringBuilder szInputStringBuild = new StringBuilder(szPlainText);
            StringBuilder szOutStringBuild = new StringBuilder(szPlainText.Length);
            char Textch;
            for (int iCount = 0; iCount < szPlainText.Length; iCount++)
            {
                Textch = szInputStringBuild[iCount];
                Textch = (char)(Textch ^ szEncryptionKey);
                szOutStringBuild.Append(Textch);
            }
            return szOutStringBuild.ToString();
        }
    }
}
