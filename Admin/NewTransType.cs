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
    public partial class NewTransType : Form
    {
        public NewTransType()
        {
            InitializeComponent();
        }

        private void checkEdit2_CheckedChanged(object sender, EventArgs e)
        {

        }

        private void simpleButton2_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void simpleButton1_Click(object sender, EventArgs e)
        {
            if(txtCode.Text == "" || txtDescription.Text == "")
            {
                MessageBox.Show("Specify all the details!", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            using(SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("spAddTransType", conn);
                    cmd.CommandType = CommandType.StoredProcedure;

                    SqlParameter p1 = new SqlParameter("@code", txtCode.Text);
                    SqlParameter p2 = new SqlParameter("@desc", txtDescription.Text);
                    SqlParameter p3 = new SqlParameter("@auto", chkAuto.Checked);
                    SqlParameter p4 = new SqlParameter("@credit", chkCredit.Checked);

                    cmd.Parameters.Add(p1);
                    cmd.Parameters.Add(p2);
                    cmd.Parameters.Add(p3);
                    cmd.Parameters.Add(p4);

                    cmd.ExecuteNonQuery();

                    txtDescription.Text = ""; txtCode.Text = "";

                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
            }
        }
    }
}
