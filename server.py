#!/usr/bin/env python3
#
# Use Python Flask to serve pages and data.

import csv, os, shutil
import psycopg2, psycopg2.extras
from openpyxl import load_workbook
from flask import Flask, Markup, Response, render_template, request, redirect

app = Flask(__name__)
api = 'http://localhost:3010/'

conn = psycopg2.connect(dbname='nova')
cur = conn.cursor()

tcell_dst_headers = [
"tcell_id",
"reference_id",
"Data Field",
"Epitope Name",
"Epitope Data Location",
"Epitope Object Type↓",
"Epitope Linear Sequence",
"Modified Residues",
"Modification↓",
"Source Antigen ID",
"Author Start",
"Author Stop",
"Epitope Source Organism Taxonomy ID",
"Epitope Evidence Code↓",
"Epitope Structure Defines↓",
"Epitope Comments",
"Assay Data Location",
"Host Organism Tax ID",
"Host Organism Sex↓",
"Host Organism Age",
"Host Geolocation ID",
"MHC Types Present",
"1st In Vivo Process Type↓",
"Disease ID",
"Disease Stage↓",
"In Vivo Immunogen Reference Name",
"Immunogen-Epitope Relation↓",
"Immunogen Object Sub-Type↓",
"Immunogen Linear Sequence",
"Modified Residues",
"Modification↓",
"Immunogen Accession ID",
"Immunogen Source Accession ID",
"Immunogen Taxonomy ID",
"Immunogen Evidence Code↓",
"Adjuvants↓",
"Route↓",
"Dose Schedule",
"In Vitro Admin Process Type↓",
"Responder Cell Type↓",
"Stimulator Cell Type↓",
"In Vitro Immunogen Ref Name",
"In Vitro Immunogen-Epitope Relation↓",
"In Vitro Immunogen Object Sub-Type↓",
"In Vitro Immunogen Linear Sequence",
"Modified Residues",
"Modification↓",
"In Vitro Immunogen Accession ID",
"In Vitro Immunogen Source Accession ID",
"In Vitro Immunogen Taxonomy ID",
"In Vitro Immunogen Evidence Code↓",
"Immunization Comments",
"Assay Type↓",
"Assay Response↓",
"Assay Units↓",
"Qualitative Measurement↓",
"Quantitative Measurement",
"Number of Subjects Tested",
"Number of Subjects Responded",
"Response Frequency",
"Effector Cell Tissue Type↓",
"Effector Cell Type↓",
"Effector Cell Culture Conditions↓",
"APC Tissue Type↓",
"APC Cell Type↓",
"APC Culture Conditions↓",
"Autologous or Syngeneic↓",
"MHC Allele Name",
"MHC Evidence Code↓",
"Antigen Reference Name",
"Antigen-Epitope Relation↓",
"Antigen Object Sub-Type↓",
"Antigen Linear Sequence",
"Modified Residues",
"Modification↓",
"Antigen Accession ID",
"Antigen Source Accession ID",
"Antigen Taxonomy ID",
"Antigen Evidence Code↓",
"Assay Comments"
]

def get_column_names(description):
  headers = []
  for column in description:
    headers.append(column[0])
  return headers

problems = [
  ['20002','error','Message',1,1,'qualitative_measurement']
]

assay_problems = {
  1: {
    'qualitative_measurement':
    ['20002','error','Message',1,1,'qualitative_measurement'],
    'epitope_name':
    ['20003','warning','Message',1,1,'epitope_name']
  }
}
assay_problems = {}

def build_cell(assay_id, column, cell):
  content = '<td>'

  try:
    problem = assay_problems[assay_id][column]
    if problem:
      content = '<td class="%s">' % problem[1]
  except:
    pass

  if not cell:
    pass
  elif column == 'reference_id':
    content += '<a href="/reference/%s">%s</a>' % (cell, cell)
  #elif column == 'assay_id':
  #  content += '<a href="/assay/%s">%s</a>' % (cell, cell)
  #elif column == 'epitope_id':
  #  content += '<a href="/epitope/%s">%s</a>' % (cell, cell)
  #elif column == 'host_id':
  #  content += '<a href="/host/%s">%s</a>' % (cell, cell)
  #elif column.endswith('object_id'):
  #  content += '<a href="/object/%s">%s</a>' % (cell, cell)
  #elif column.endswith('process_id'):
  #  content += '<a href="/process/%s">%s</a>' % (cell, cell)
  else:
    content += str(cell)

  content += '</td>'
  return content

def build_table(columns, column_names, rows):
  content = '<table class="table">'
  content += '<tr>'
  for column_name in column_names:
    content += '<th>%s</th>' % column_name
  content += '</tr>'

  for row in rows:
    content += '<tr>'
    for i in range(0, len(columns)):
      content += build_cell(1, columns[i], row[i])
    content += '</tr>'
  content += '</table>'
  return content

def build_table_2(cursor):
  column_names = get_column_names(cursor.description)
  return build_table(column_names, column_names, cursor.fetchall())

def process_dst():
  status = 'started loading TCell DST'
  query = '''INSERT INTO core.reference (status)
VALUES (%s)
RETURNING reference_id;'''
  cur.execute(query, (status,))
  reference_id = cur.fetchone()[0]

  conn.commit()

  tmpdir = 'tmp/ref_%d' % reference_id

  f = request.files['input']
  if not f:
    return 'No file submitted'
  os.makedirs(tmpdir)
  in_path = tmpdir + '/input.xlsx'
  f.save(in_path)

  wb = load_workbook(filename=in_path, read_only=True)
  ws = wb.active

  rows = []
  for row in ws.rows:
    r = []
    for cell in row:
      r.append(cell.value)
    if all(v is None for v in r):
      break
    rows.append([reference_id] + r)

  tsv_path = tmpdir + '/input.tsv'
  with open(tsv_path, 'w', newline='') as tsv_file:
    writer = csv.writer(tsv_file, delimiter='\t', lineterminator='\n')
    for row in rows[3:]:
      writer.writerow(row)

  cur.execute('SELECT * FROM dst.tcell LIMIT 0')
  headers = get_column_names(cur.description)
  with open(tsv_path, 'r') as tsv_file:
    cur.copy_from(tsv_file, 'dst.tcell', null='', columns=headers[1:])

  status = 'loaded TCell DST'
  query = '''UPDATE core.reference
SET status = %s
WHERE reference_id = %s;'''
  cur.execute(query, (status, reference_id))
  conn.commit()

  query = open('src/convert-tcell-dst.sql', 'r').read()
  cur.execute(query, (reference_id,))
  conn.commit()

  return redirect('/reference/%d' % reference_id)

@app.route('/', methods=['GET','POST'])
def my_app():
  if request.method == 'POST':
    return process_dst()
  else:
    return render_template('/index.html')

@app.route('/reference/', methods=['GET'])
def references():
  content = '<h1>References</h1>'
  cur.execute('SELECT * FROM core.reference ORDER BY reference_id')
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)
  return render_template('/base.html', content=(Markup(content)))

@app.route('/reference/<reference_id>', methods=['GET'])
def reference(reference_id):
  reference_id = int(reference_id)
  content = '<h1>Reference %d</h1>' % reference_id

  content += '<h2>core.reference</h2>'
  query = 'SELECT * FROM core.reference WHERE reference_id = %s'
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)

  content += '<h2>core.assay</h2>'
  query = 'SELECT * FROM core.assay WHERE reference_id = %s'
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)

  content += '<h2>core.epitope</h2>'
  query = 'SELECT * FROM core.epitope WHERE reference_id = %s'
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)

  content += '<h2>core.host</h2>'
  query = 'SELECT * FROM core.host WHERE reference_id = %s'
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)

  content += '<h2>core.process</h2>'
  query = 'SELECT * FROM core.process WHERE reference_id = %s'
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)

  content += '<h2>core.object</h2>'
  query = 'SELECT * FROM core.object WHERE reference_id = %s'
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)

  content += '<h2>joined.assay</h2>'
  query = 'SELECT * FROM joined.assay WHERE reference_id = %s'
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)

  content += '<h2>dst.tcell</h2>'
  query = '''SELECT *
FROM dst.tcell
WHERE reference_id = %s
ORDER BY tcell_id'''
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table(get_column_names(cur.description), tcell_dst_headers, cur.fetchall())

  return render_template('/base.html', content=(Markup(content)))

@app.errorhandler(404)
def page_not_found(error):
  return render_template('error.html'), 404

if __name__ == '__main__':
  app.debug = True
  app.run(host='0.0.0.0', port=3012, threaded=True)
