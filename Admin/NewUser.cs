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
    public partial class NewUser : Form
    {
        public NewUser()
        {
            InitializeComponent();
        }

        private void simpleButton2_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void NewUser_Load(object sender, EventArgs e)
        {
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select profilename from tblProfiles order by profilename", conn);
                    SqlDataReader rd = cmd.ExecuteReader();

                    while(rd.Read())
                    {
                        cmbdGroup.Properties.Items.Add(rd[0].ToString());
                    }
                    rd.Close();
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Failed to comnnect to database! " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            if(txtUsername.Text == "")
            {
                MessageBox.Show("Specify username!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            if (cmbdGroup.Text == "")
            {
                MessageBox.Show("Specify user group!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
            
            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddRemoveUser", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    SqlParameter p1 = new SqlParameter("@username", txtUsername.Text);
                    SqlParameter p2 = new SqlParameter("@first", txtUsername.Text);
                    SqlParameter p3 = new SqlParameter("@last", txtLastname.Text);
                    SqlParameter p4 = new SqlParameter("@pass", txtPassword.Text);
                    SqlParameter p5 = new SqlParameter("@group", cmbdGroup.Text);
                    SqlParameter p6 = new SqlParameter("@code", 1);

                    cmd.Parameters.Add(p1); cmd.Parameters.Add(p2); cmd.Parameters.Add(p3);
                    cmd.Parameters.Add(p4); cmd.Parameters.Add(p5); cmd.Parameters.Add(p6);
                    cmd.ExecuteNonQuery();

                    txtUsername.Text = ""; txtFirstname.Text = ""; txtLastname.Text = "";
                    txtPassword.Text = ""; cmbdGroup.Text = "";
                }
                catch(Exception ex)
                {
                    MessageBox.Show("Error! " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
    }
}
