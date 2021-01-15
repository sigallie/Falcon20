using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Reflection;

using DevExpress.DataAccess;
using DevExpress.DataAccess.ConnectionParameters;

using System.Data.SqlClient;
using System.Windows.Forms;

namespace DBUtils
{
    public class ClassDBUtils
    {
        public static string DBConnString
        {
            get
            {
                try
                {
                    string fileName = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) + "\\DBconnect.txt";
                    return File.ReadAllLines(fileName)[0];
                }
                catch (Exception fnf)
                {
                    fnf.ToString();
                    return null;

                }

            }
        }

        public static Boolean IsAllowed(string user, string userFunction)
        {
            Boolean allowed = false;

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select dbo.fnCheckAccess('"+user+"','"+userFunction+"')", conn);
                    allowed = Convert.ToBoolean(cmd.ExecuteScalar());
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
            return allowed;
        }
    }
}
