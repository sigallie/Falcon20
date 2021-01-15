using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;

using DBUtils;

namespace Admin
{
    public partial class ForgotPassword : Form
    {
        string loginUser = "";
        string answer = "";
        public ForgotPassword(string usr)
        {
            InitializeComponent();
            loginUser = usr;
        }

        private void ForgotPassword_Load(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select question, answer from users where [login] = '" + loginUser + "'", conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    while(rd.Read())
                    {
                        txtLogin.Text = rd[0].ToString();
                        answer = rd[1].ToString();
                    }
                    rd.Close();
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason " +ex.Message,  "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
        }

        private void simpleButton2_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            if (txtAnswer.Text == "")
            {
                MessageBox.Show("Please supply the response to the question!", "Falcon",MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    //compare answer supplied to value obtained from database
                    if (txtAnswer.Text == answer)
                    {
                        UserResetPassword ureset = new UserResetPassword(loginUser);
                        ureset.ShowDialog();
                    }
                    else
                    {
                        MessageBox.Show("Incorrect answer to security question!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    }

                }
                catch(Exception ex)
                {
                    MessageBox.Show("Error connecting to database! Reason " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                finally
                {
                    if (conn != null)
                        conn.Close();
                }
            }
        }
    }
}
