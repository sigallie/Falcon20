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
    public partial class DatabaseConfig : Form
    {
        public DatabaseConfig()
        {
            InitializeComponent();
        }

        private void DatabaseConfig_Load(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select DBServerIP, DBName, DBUsername, DBPassword from tblSystemParams", conn);
                    SqlDataReader rd = cmd.ExecuteReader();

                    while (rd.Read())
                    {
                        txtIP.Text = rd[0].ToString();
                        txtDB.Text = rd[1].ToString();
                        txtUsername.Text = rd[2].ToString();
                        txtPassword.Text = rd[3].ToString();
                    }
                    rd.Close();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Failed to connect to database! " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    string strSQL = "update tblSystemParams set DBServerIP='" + txtIP.Text + "', dbname='" + txtDB.Text + "', dbusername='" + txtUsername.Text + "', dbpassword='" + txtPassword.Text + "'";
                    SqlCommand cmd = new SqlCommand(strSQL, conn);
                    cmd.ExecuteNonQuery();
                    MessageBox.Show("Database settings saved successfully!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Failed to connect to database! " + ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
    }
}
