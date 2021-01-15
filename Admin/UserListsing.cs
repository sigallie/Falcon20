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
using GenLib;

namespace Admin
{
    public partial class UserListsing : Form
    {
        public UserListsing()
        {
            InitializeComponent();
        }

        private void UserListsing_Load(object sender, EventArgs e)
        {
            using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
            {
                try
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand("select * from users order by login", conn);
                    using(SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        grdUsers.DataSource = dt;
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

        private void resetPasswordToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "RESET USER PASSWORD") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            string usr = "";

            for(int i = 0; i < vwUsers.RowCount; i++)
            {
                if(vwUsers.IsRowSelected(i))
                {
                    usr = vwUsers.GetRowCellValue(i, "LOGIN").ToString();
                    break;
                }
            }
            UserResetPassword rest = new UserResetPassword(usr);
            rest.ShowDialog();
        }

        private void addNewUserToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "ADD NEW USER") == true)
            {
                NewUser nu = new NewUser();
                nu.ShowDialog();

                UserListsing_Load(sender, e);
            }
            else
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
        }

        private void unLockUserToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "(UN)LOCK USER") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }

            if(MessageBox.Show("A locked user cannot login. Proceed?", "Falcon", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == System.Windows.Forms.DialogResult.Yes)
            {
                string user = "";

                for(int i = 0; i < vwUsers.RowCount; i++)
                {
                    if(vwUsers.IsRowSelected(i))
                    {
                        user = vwUsers.GetRowCellValue(i, "LOGIN").ToString();
                        break;
                    }
                }

                using (SqlConnection conn = new SqlConnection(ClassDBUtils.DBConnString))
                {
                    try
                    {
                        conn.Open();
                        SqlCommand cmd = new SqlCommand("spLockUnlockUser", conn);
                        cmd.CommandType = CommandType.StoredProcedure;
                        SqlParameter p1 = new SqlParameter("@user", user);
                        cmd.Parameters.Add(p1);
                        cmd.ExecuteNonQuery();

                        UserListsing_Load(sender, e);
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

        private void editUserDetailsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (ClassDBUtils.IsAllowed(ClassGenLib.username, "EDIT USER DETAILS") == false)
            {
                MessageBox.Show("Access denied! Insufficient rights to perform the function.", "Falcon", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return;
            }
        }
    }
}
