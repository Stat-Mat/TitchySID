namespace sidsample_csharp
{
    partial class IDD_SID_PLAYER_DLG
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(IDD_SID_PLAYER_DLG));
            this.IDC_OPEN = new System.Windows.Forms.Button();
            this.IDC_EXIT = new System.Windows.Forms.Button();
            this.IDC_PLAY = new System.Windows.Forms.Button();
            this.IDC_PAUSE_RESUME = new System.Windows.Forms.Button();
            this.IDC_STOP = new System.Windows.Forms.Button();
            this.IDC_PREVIOUS = new System.Windows.Forms.Button();
            this.IDC_NEXT = new System.Windows.Forms.Button();
            this.IDC_STATIC = new System.Windows.Forms.GroupBox();
            this.IDC_SONG_NUM = new System.Windows.Forms.Label();
            this.IDC_SUBSONG = new System.Windows.Forms.Label();
            this.IDC_SPEC = new System.Windows.Forms.PictureBox();
            this.sidInfoGroupBox = new System.Windows.Forms.GroupBox();
            this.IDC_INFO = new System.Windows.Forms.TextBox();
            this.IDC_INFO_LABELS = new System.Windows.Forms.TextBox();
            this.IDC_STATIC.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.IDC_SPEC)).BeginInit();
            this.sidInfoGroupBox.SuspendLayout();
            this.SuspendLayout();
            // 
            // IDC_OPEN
            // 
            this.IDC_OPEN.FlatStyle = System.Windows.Forms.FlatStyle.System;
            this.IDC_OPEN.Location = new System.Drawing.Point(355, 22);
            this.IDC_OPEN.Margin = new System.Windows.Forms.Padding(0);
            this.IDC_OPEN.Name = "IDC_OPEN";
            this.IDC_OPEN.Size = new System.Drawing.Size(52, 19);
            this.IDC_OPEN.TabIndex = 0;
            this.IDC_OPEN.Text = "Open";
            this.IDC_OPEN.UseCompatibleTextRendering = true;
            this.IDC_OPEN.UseVisualStyleBackColor = true;
            this.IDC_OPEN.Click += new System.EventHandler(this.IDC_OPEN_Click);
            // 
            // IDC_EXIT
            // 
            this.IDC_EXIT.FlatStyle = System.Windows.Forms.FlatStyle.System;
            this.IDC_EXIT.Location = new System.Drawing.Point(414, 22);
            this.IDC_EXIT.Margin = new System.Windows.Forms.Padding(0);
            this.IDC_EXIT.Name = "IDC_EXIT";
            this.IDC_EXIT.Size = new System.Drawing.Size(52, 19);
            this.IDC_EXIT.TabIndex = 1;
            this.IDC_EXIT.Text = "Exit";
            this.IDC_EXIT.UseCompatibleTextRendering = true;
            this.IDC_EXIT.UseVisualStyleBackColor = true;
            this.IDC_EXIT.Click += new System.EventHandler(this.IDC_EXIT_Click);
            // 
            // IDC_PLAY
            // 
            this.IDC_PLAY.FlatStyle = System.Windows.Forms.FlatStyle.System;
            this.IDC_PLAY.Location = new System.Drawing.Point(329, 59);
            this.IDC_PLAY.Margin = new System.Windows.Forms.Padding(0);
            this.IDC_PLAY.Name = "IDC_PLAY";
            this.IDC_PLAY.Size = new System.Drawing.Size(52, 19);
            this.IDC_PLAY.TabIndex = 2;
            this.IDC_PLAY.Text = "Play";
            this.IDC_PLAY.UseCompatibleTextRendering = true;
            this.IDC_PLAY.UseVisualStyleBackColor = true;
            this.IDC_PLAY.Click += new System.EventHandler(this.IDC_PLAY_Click);
            // 
            // IDC_PAUSE_RESUME
            // 
            this.IDC_PAUSE_RESUME.FlatStyle = System.Windows.Forms.FlatStyle.System;
            this.IDC_PAUSE_RESUME.Location = new System.Drawing.Point(384, 59);
            this.IDC_PAUSE_RESUME.Margin = new System.Windows.Forms.Padding(0);
            this.IDC_PAUSE_RESUME.Name = "IDC_PAUSE_RESUME";
            this.IDC_PAUSE_RESUME.Size = new System.Drawing.Size(52, 19);
            this.IDC_PAUSE_RESUME.TabIndex = 3;
            this.IDC_PAUSE_RESUME.Text = "Pause";
            this.IDC_PAUSE_RESUME.UseCompatibleTextRendering = true;
            this.IDC_PAUSE_RESUME.UseVisualStyleBackColor = true;
            this.IDC_PAUSE_RESUME.Click += new System.EventHandler(this.IDC_PAUSE_RESUME_Click);
            // 
            // IDC_STOP
            // 
            this.IDC_STOP.FlatStyle = System.Windows.Forms.FlatStyle.System;
            this.IDC_STOP.Location = new System.Drawing.Point(439, 59);
            this.IDC_STOP.Margin = new System.Windows.Forms.Padding(0);
            this.IDC_STOP.Name = "IDC_STOP";
            this.IDC_STOP.Size = new System.Drawing.Size(52, 19);
            this.IDC_STOP.TabIndex = 4;
            this.IDC_STOP.Text = "Stop";
            this.IDC_STOP.UseCompatibleTextRendering = true;
            this.IDC_STOP.UseVisualStyleBackColor = true;
            this.IDC_STOP.Click += new System.EventHandler(this.IDC_STOP_Click);
            // 
            // IDC_PREVIOUS
            // 
            this.IDC_PREVIOUS.FlatStyle = System.Windows.Forms.FlatStyle.System;
            this.IDC_PREVIOUS.Location = new System.Drawing.Point(6, 19);
            this.IDC_PREVIOUS.Margin = new System.Windows.Forms.Padding(0);
            this.IDC_PREVIOUS.Name = "IDC_PREVIOUS";
            this.IDC_PREVIOUS.Size = new System.Drawing.Size(52, 19);
            this.IDC_PREVIOUS.TabIndex = 5;
            this.IDC_PREVIOUS.Text = "Previous";
            this.IDC_PREVIOUS.UseCompatibleTextRendering = true;
            this.IDC_PREVIOUS.UseVisualStyleBackColor = true;
            this.IDC_PREVIOUS.Click += new System.EventHandler(this.IDC_PREVIOUS_Click);
            // 
            // IDC_NEXT
            // 
            this.IDC_NEXT.FlatStyle = System.Windows.Forms.FlatStyle.System;
            this.IDC_NEXT.Location = new System.Drawing.Point(102, 19);
            this.IDC_NEXT.Margin = new System.Windows.Forms.Padding(0);
            this.IDC_NEXT.Name = "IDC_NEXT";
            this.IDC_NEXT.Size = new System.Drawing.Size(52, 19);
            this.IDC_NEXT.TabIndex = 6;
            this.IDC_NEXT.Text = "Next";
            this.IDC_NEXT.UseCompatibleTextRendering = true;
            this.IDC_NEXT.UseVisualStyleBackColor = true;
            this.IDC_NEXT.Click += new System.EventHandler(this.IDC_NEXT_Click);
            // 
            // IDC_STATIC
            // 
            this.IDC_STATIC.Controls.Add(this.IDC_SONG_NUM);
            this.IDC_STATIC.Controls.Add(this.IDC_SUBSONG);
            this.IDC_STATIC.Controls.Add(this.IDC_PREVIOUS);
            this.IDC_STATIC.Controls.Add(this.IDC_NEXT);
            this.IDC_STATIC.Location = new System.Drawing.Point(330, 94);
            this.IDC_STATIC.Name = "IDC_STATIC";
            this.IDC_STATIC.RightToLeft = System.Windows.Forms.RightToLeft.No;
            this.IDC_STATIC.Size = new System.Drawing.Size(160, 49);
            this.IDC_STATIC.TabIndex = 8;
            this.IDC_STATIC.TabStop = false;
            // 
            // IDC_SONG_NUM
            // 
            this.IDC_SONG_NUM.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.IDC_SONG_NUM.Location = new System.Drawing.Point(65, 19);
            this.IDC_SONG_NUM.Name = "IDC_SONG_NUM";
            this.IDC_SONG_NUM.Size = new System.Drawing.Size(30, 18);
            this.IDC_SONG_NUM.TabIndex = 10;
            this.IDC_SONG_NUM.Text = "Song";
            this.IDC_SONG_NUM.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // IDC_SUBSONG
            // 
            this.IDC_SUBSONG.AutoSize = true;
            this.IDC_SUBSONG.Location = new System.Drawing.Point(55, -1);
            this.IDC_SUBSONG.Name = "IDC_SUBSONG";
            this.IDC_SUBSONG.Size = new System.Drawing.Size(50, 14);
            this.IDC_SUBSONG.TabIndex = 9;
            this.IDC_SUBSONG.Text = "Subsong";
            // 
            // IDC_SPEC
            // 
            this.IDC_SPEC.Enabled = false;
            this.IDC_SPEC.Location = new System.Drawing.Point(66, 161);
            this.IDC_SPEC.Name = "IDC_SPEC";
            this.IDC_SPEC.Size = new System.Drawing.Size(368, 127);
            this.IDC_SPEC.TabIndex = 10;
            this.IDC_SPEC.TabStop = false;
            // 
            // sidInfoGroupBox
            // 
            this.sidInfoGroupBox.Controls.Add(this.IDC_INFO);
            this.sidInfoGroupBox.Controls.Add(this.IDC_INFO_LABELS);
            this.sidInfoGroupBox.Location = new System.Drawing.Point(11, 5);
            this.sidInfoGroupBox.Name = "sidInfoGroupBox";
            this.sidInfoGroupBox.Size = new System.Drawing.Size(309, 138);
            this.sidInfoGroupBox.TabIndex = 11;
            this.sidInfoGroupBox.TabStop = false;
            // 
            // IDC_INFO
            // 
            this.IDC_INFO.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.IDC_INFO.Location = new System.Drawing.Point(75, 8);
            this.IDC_INFO.Multiline = true;
            this.IDC_INFO.Name = "IDC_INFO";
            this.IDC_INFO.Size = new System.Drawing.Size(229, 128);
            this.IDC_INFO.TabIndex = 13;
            // 
            // IDC_INFO_LABELS
            // 
            this.IDC_INFO_LABELS.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.IDC_INFO_LABELS.Location = new System.Drawing.Point(1, 8);
            this.IDC_INFO_LABELS.Multiline = true;
            this.IDC_INFO_LABELS.Name = "IDC_INFO_LABELS";
            this.IDC_INFO_LABELS.Size = new System.Drawing.Size(78, 128);
            this.IDC_INFO_LABELS.TabIndex = 12;
            this.IDC_INFO_LABELS.Text = "Load addr:\r\nInit addr:\r\nPlay addr:\r\nData size:\r\nNum songs:\r\nDefault song:\r\nName:\r" +
    "\nAuthor:\r\nCopyright:";
            // 
            // IDD_SID_PLAYER_DLG
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 14F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(500, 306);
            this.Controls.Add(this.sidInfoGroupBox);
            this.Controls.Add(this.IDC_SPEC);
            this.Controls.Add(this.IDC_STATIC);
            this.Controls.Add(this.IDC_STOP);
            this.Controls.Add(this.IDC_PAUSE_RESUME);
            this.Controls.Add(this.IDC_PLAY);
            this.Controls.Add(this.IDC_EXIT);
            this.Controls.Add(this.IDC_OPEN);
            this.DoubleBuffered = true;
            this.Font = new System.Drawing.Font("Arial", 8F);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MaximizeBox = false;
            this.Name = "IDD_SID_PLAYER_DLG";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "TitchySID Library Demo (C# version)";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.IDD_SID_PLAYER_DLG_FormClosing);
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.IDD_SID_PLAYER_DLG_FormClosed);
            this.Load += new System.EventHandler(this.IDD_SID_PLAYER_DLG_Load);
            this.MouseDown += new System.Windows.Forms.MouseEventHandler(this.IDD_SID_PLAYER_DLG_MouseDown);
            this.IDC_STATIC.ResumeLayout(false);
            this.IDC_STATIC.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.IDC_SPEC)).EndInit();
            this.sidInfoGroupBox.ResumeLayout(false);
            this.sidInfoGroupBox.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button IDC_OPEN;
        private System.Windows.Forms.Button IDC_EXIT;
        private System.Windows.Forms.Button IDC_PLAY;
        private System.Windows.Forms.Button IDC_PAUSE_RESUME;
        private System.Windows.Forms.Button IDC_STOP;
        private System.Windows.Forms.Button IDC_PREVIOUS;
        private System.Windows.Forms.Button IDC_NEXT;
        private System.Windows.Forms.GroupBox IDC_STATIC;
        private System.Windows.Forms.Label IDC_SUBSONG;
        private System.Windows.Forms.Label IDC_SONG_NUM;
        private System.Windows.Forms.PictureBox IDC_SPEC;
        private System.Windows.Forms.GroupBox sidInfoGroupBox;
        private System.Windows.Forms.TextBox IDC_INFO;
        private System.Windows.Forms.TextBox IDC_INFO_LABELS;
    }
}

