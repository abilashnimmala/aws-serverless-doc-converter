import json
import boto3
import logging
import os
import io
import urllib.parse
from fpdf import FPDF
from docx import Document

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')

class PDFProcessor:
    @staticmethod
    def txt_to_pdf(content, output_path):
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Arial", size=12)
        pdf.multi_cell(0, 10, content)
        pdf.output(output_path)

    @staticmethod
    def docx_to_pdf(file_stream, output_path):
        try:
            doc = Document(file_stream)
            pdf = FPDF()
            pdf.add_page()
            pdf.set_font("Arial", size=11)
            
            for para in doc.paragraphs:
                # Clean text to avoid FPDF encoding issues (latin-1)
                text = para.text.encode('latin-1', 'replace').decode('latin-1')
                if text.strip():
                    pdf.multi_cell(0, 8, text)
                    pdf.ln(2)
            
            pdf.output(output_path)
        except Exception as e:
            logger.error(f"DOCX Conversion Error: {str(e)}")
            raise

    @staticmethod
    def html_to_pdf(content, output_path):
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Arial", size=12)
        # fpdf2 has basic HTML support
        pdf.write_html(content)
        pdf.output(output_path)

def lambda_handler(event, context):
    try:
        output_bucket = os.environ.get('OUTPUT_BUCKET_NAME')
        if not output_bucket:
            raise ValueError("OUTPUT_BUCKET_NAME environment variable is not set")

        for record in event['Records']:
            input_bucket = record['s3']['bucket']['name']
            raw_key = record['s3']['object']['key']
            input_key = urllib.parse.unquote_plus(raw_key)
            file_ext = os.path.splitext(input_key)[1].lower()
            
            if file_ext == '.pdf':
                logger.info(f"Skipping {input_key} (already a PDF)")
                continue

            logger.info(f"Converting {input_key} to PDF")
            
            response = s3_client.get_object(Bucket=input_bucket, Key=input_key)
            file_content = response['Body'].read()
            
            output_key = os.path.splitext(input_key)[0] + ".pdf"
            tmp_pdf_path = f"/tmp/{output_key.split('/')[-1]}"
            
            if file_ext == '.txt':
                PDFProcessor.txt_to_pdf(file_content.decode('utf-8', errors='ignore'), tmp_pdf_path)
            elif file_ext == '.docx':
                PDFProcessor.docx_to_pdf(io.BytesIO(file_content), tmp_pdf_path)
            elif file_ext == '.html' or file_ext == '.htm':
                PDFProcessor.html_to_pdf(file_content.decode('utf-8', errors='ignore'), tmp_pdf_path)
            else:
                logger.warning(f"Unsupported file format: {file_ext}")
                continue

            with open(tmp_pdf_path, "rb") as f:
                s3_client.put_object(
                    Bucket=output_bucket,
                    Key=output_key,
                    Body=f.read(),
                    ContentType='application/pdf'
                )
            
            if os.path.exists(tmp_pdf_path):
                os.remove(tmp_pdf_path)

            logger.info(f"Successfully converted {input_key} to {output_key}")

        return {
            'statusCode': 200,
            'body': json.dumps('PDF conversion completed')
        }

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }
