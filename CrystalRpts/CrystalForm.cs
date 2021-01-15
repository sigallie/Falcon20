using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using CrystalDecisions.Shared;
using CrystalDecisions.CrystalReports.Engine;
using System.IO;
using System.Reflection;

using GenLib;

namespace CrystalRpts
{
    public partial class CrystalForm : Form
    {
        string dealno = "";
        string rptName = "";
        string clientNo = "";
        DateTime startDate = DateTime.Now;
        DateTime endDate = DateTime.Now;
        public CrystalForm(string rpt, string dno, string cno, DateTime start, DateTime end)
        {
            InitializeComponent();

            dealno = dno;
            rptName = rpt;
            clientNo = cno;
            startDate = start;
            endDate = end;
        }

        private void CrystalForm_Load(object sender, EventArgs e)
        {

            ReportDocument cryRpt = new ReportDocument();

            string rptPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

            if (rptName == "SNOTE")
            {
                //SNOTE snote = new SNOTE();
                //snote.SetParameterValue("dno", dealno);
                //rptViewer.ReportSource = snote;


                cryRpt.Load(rptPath+ @"\FalconReports\SNOTE.rpt");

                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                crParameterDiscreteValue.Value = dealno;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["DEALNO"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                rptViewer.ReportSource = cryRpt;
            }


            if (rptName == "BNOTE")
            {
                //BNOTE snote = new BNOTE();
                //snote.SetParameterValue("dno", dealno);
                //rptViewer.ReportSource = snote;
                //MessageBox.Show(rpath);

                cryRpt.Load(rptPath + @"\FalconReports\BNOTE.rpt");

                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                crParameterDiscreteValue.Value = dealno;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["dealno"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                rptViewer.ReportSource = cryRpt;
            }

            if(rptName == "DayBook")
            {
                //cryRpt.SetParameterValue("dealdate", dealno); //deal date has been sent as a string
                cryRpt.Load(rptPath +@"\FalconReports\Daybook.rpt");

                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                crParameterDiscreteValue.Value = dealno;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["dealdate"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                rptViewer.ReportSource = cryRpt;
                //rptViewer.Refresh();
            }

            

            if (rptName.Contains("Ledger"))
            {
                cryRpt.Load(rptPath +@"\FalconReports\LedgerReport.rpt");

                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                crParameterDiscreteValue.Value = ClassGenLib.username;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["username"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = rptName.Substring(rptName.IndexOf("-") + 2);
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["ledger"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = startDate;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["start"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = endDate;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["end"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                rptViewer.ReportSource = cryRpt;
            }

            if(rptName == "STATEMENT")
            {
                cryRpt.Load(rptPath + @"\FalconReports\Statement.rpt");

                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                crParameterDiscreteValue.Value = ClassGenLib.username;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["USER"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = clientNo;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["ClientNo"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = startDate;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["StartDate"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = endDate;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["EndDate"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                rptViewer.ReportSource = cryRpt;
            }

            if (rptName.Contains("Cashbook"))
            {
                cryRpt.Load(rptPath + @"\FalconReports\Cashbook.rpt");

                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                crParameterDiscreteValue.Value = ClassGenLib.username;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["username"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = rptName.Substring(rptName.IndexOf("-") + 2);
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["cashbook"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = startDate;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["start"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);


                crParameterDiscreteValue.Value = endDate;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["end"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;

                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                rptViewer.ReportSource = cryRpt;
            }

            rptViewer.Refresh();
        }
    }
}
