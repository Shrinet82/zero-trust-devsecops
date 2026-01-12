# Use a slim, non-root image for a smaller attack surface
FROM python:3.9-slim

# Create a non-privileged user to run the app
RUN useradd -m devopsuser
USER devopsuser
WORKDIR /home/devopsuser

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
