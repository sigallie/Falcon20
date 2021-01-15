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
    public partial class UserResetPassword : Form
    {
        string loginUser = "";
        public UserResetPassword(string usr)
        {
            InitializeComponent();
            loginUser = usr;
        }

        private void simpleButton2_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            if(txtPassword.Text != txtConfirm.Text)
            {
                MessageBox.Show("Password mismatch!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            if(cmbQuestion.Text == "" || txtAnswer.Text == "")
            {
                MessageBox.Show("Specify the security question and answer!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("update users set pass='"+txtConfirm.Text+"', question = '"+cmbQuestion.Text+"', answer='"+txtAnswer.Text+"', temppass=0 where [login] = '"+loginUser+"'", conn);
                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Password changed successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    txtAnswer.Text = ""; txtConfirm.Text = ""; txtPassword.Text = "";
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

        private void UserResetPassword_Load(object sender, EventArgs e)
        {
            txtUsername.Text = loginUser;

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select question from  passquestions order by question", conn);
                    SqlDataReader rd = cmd.ExecuteReader();
                    while(rd.Read())
                    {
                        cmbQuestion.Properties.Items.Add(rd[0].ToString());
                    }
                    
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
        }
    }
}
