#!/usr/bin/env python3
#
# Use Python Flask to serve pages and data.

# To run in development mode, do:
# export FLASK_APP=server.py
# export FLASK_DEBUG=1 (optional; do not enable this if you want to access the server remotely)
# python3 -m flask run

import psycopg2
from flask import Flask, Markup, render_template, request

app = Flask(__name__)
api = 'http://localhost:3010/'

conn = psycopg2.connect(dbname='iedb')
cur = conn.cursor()


def get_column_names(description):
  headers = []
  for column in description:
    headers.append(column[0])
  return headers


problems = [
  ['20002', 'error', 'Message', 1, 1, 'qualitative_measurement']
]

assay_problems = {
  1: {
    'qualitative_measurement':
    ['20002', 'error', 'Message', 1, 1, 'qualitative_measurement'],
    'epitope_name':
    ['20003', 'warning', 'Message', 1, 1, 'epitope_name']
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


@app.route('/', methods=['GET', 'POST'])
def my_app():
  if request.method == 'POST':
    pass
  else:
    return render_template('/index.html')


@app.route('/reference/', methods=['GET'])
def references():
  content = '<h1>References</h1>'
  cur.execute('SELECT DISTINCT reference_id FROM core.object ORDER BY reference_id')
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)
  return render_template('/base.html', content=(Markup(content)))


@app.route('/reference/<reference_id>', methods=['GET'])
def reference(reference_id):
  reference_id = int(reference_id)
  content = '<h1>Reference %d</h1>' % reference_id

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

  content += '<h2>upstream.tcell</h2>'
  query = '''SELECT *
FROM upstream.tcell
WHERE reference_id = %s
ORDER BY tcell_id'''
  cur.execute(query, (reference_id,))
  content += '<p>%s</p>' % cur.statusmessage
  content += build_table_2(cur)

  return render_template('/base.html', content=(Markup(content)))


@app.errorhandler(404)
def page_not_found(error):
  return render_template('error.html'), 404


if __name__ == '__main__':
  app.debug = True
  app.run(host='0.0.0.0', port=3012, threaded=True)
