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

using Admin;
using GenLib;
using DBUtils;

namespace WindowsFormsApplication1
{
    public partial class frmLogin : Form
    {
        public frmLogin()
        {
            InitializeComponent();
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void simpleButton2_Click(object sender, EventArgs e)
        {
            //frmMain frm = new frmMain();
            //this.Hide();
            //frm.ShowDialog();

            if (cmbUsername.Text == "" || txtPassword.Text == "")
            {
                MessageBox.Show("Invalid username or password!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string usr = ""; string ps = ""; Boolean temppass = false;

                    SqlCommand cmd = new SqlCommand("select [login], pass, temppass from users where [login] = '" + cmbUsername.Text + "'", conn);
                    SqlDataReader rd = cmd.ExecuteReader();

                    while (rd.Read())
                    {
                        usr = rd[0].ToString();
                        ps = rd[1].ToString();
                        temppass = Convert.ToBoolean(rd[2].ToString());
                    }
                    rd.Close();

                    ClassGenLib.username = cmbUsername.Text;

                    if (ps == txtPassword.Text)
                    //if(ClassGenLib.HashPass(txtPassword.Text, 2020) == ps)
                    {
                        if (temppass == true) //new user or password has been reset therefore go to password dialog
                        {
                            UserResetPassword rest = new UserResetPassword(cmbUsername.Text);
                            rest.ShowDialog();
                        }
                        else
                        {
                            frmMain frm = new frmMain();
                            this.Hide();
                            frm.ShowDialog();
                            this.Close();
                        }
                    }
                    else
                    {
                        MessageBox.Show("Invalid username or password!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error attempting to access database! " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void frmLogin_Load(object sender, EventArgs e)
        {
            cmbUsername.Focus();
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select [login] from users order by [login]", conn);
                    SqlDataReader rd = cmd.ExecuteReader();

                    while(rd.Read())
                    {
                        cmbUsername.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }

        private void cmbUsername_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
                txtPassword.Focus();
        }

        private void txtPassword_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
                simpleButton2_Click(sender, e);
        }

        private void labelControl3_Click(object sender, EventArgs e)
        {
            if(cmbUsername.Text == "")
            {
                MessageBox.Show("Specify the username!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            ForgotPassword gpass = new ForgotPassword(cmbUsername.Text);
            gpass.ShowDialog();
        }

        private void pictureEdit1_EditValueChanged(object sender, EventArgs e)
        {

        }
    }
}
