import os
import json
import boto3
import uuid
import logging
import decimal
import hashlib
from datetime import datetime
from boto3.dynamodb.conditions import Key  # Direct import for cleaner usage

# Set up basic logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Retrieve DynamoDB table names from environment variables
GOALS_TABLE_NAME = os.environ.get('GOALS_TABLE_NAME', 'default-DietGoals')
MEALS_TABLE_NAME = os.environ.get('MEALS_TABLE_NAME', 'default-MealLogs')
VALID_USERS_TABLE_NAME = os.environ.get('VALID_USERS_TABLE_NAME', 'default-ValidUsers')

# Initialize DynamoDB resource using dynamic table names
dynamodb = boto3.resource('dynamodb')
goals_table = dynamodb.Table(GOALS_TABLE_NAME)
meals_table = dynamodb.Table(MEALS_TABLE_NAME)
valid_users_table = dynamodb.Table(VALID_USERS_TABLE_NAME)

def decimal_default(obj):
    if isinstance(obj, decimal.Decimal):
        return float(obj)
    raise TypeError

def get_user_key(event):
    """
    Extracts and converts the security key from the headers into a unique user key,
    then verifies the user exists in the valid users table.
    """
    security_key = event.get("headers", {}).get("X-Security-Key")
    if not security_key:
        raise ValueError("Security key is missing.")
    user_key = hashlib.sha256(security_key.encode('utf-8')).hexdigest()
    # Validate user against the valid users table
    response = valid_users_table.get_item(Key={'user': user_key})
    if 'Item' not in response:
        raise ValueError("Unauthorized: Invalid user.")
    return user_key

def set_goals(event):
    """
    Expected JSON body:
    {
        "date": "YYYY-MM-DD",
        "calories": 2000,
        "protein": 150,
        "carbs": 250,
        "fat": 70
    }
    """
    try:
        user_key = get_user_key(event)
        data = json.loads(event.get('body', '{}'))
        date = data.get('date')
        if not date:
            return response(400, "Date is required.")

        # Store the daily goals in the DynamoDB table with the user key
        goals_table.put_item(Item={
            'user': user_key,
            'date': date,
            'calories': data.get('calories', 0),
            'protein': data.get('protein', 0),
            'carbs': data.get('carbs', 0),
            'fat': data.get('fat', 0)
        })
        return response(200, f"Goals for {date} set successfully.")
    except ValueError as ve:
        return response(401, str(ve))
    except Exception as e:
        logger.error("Error in set_goals: %s", e, exc_info=True)
        return response(500, str(e))

def log_meal(event):
    """
    Expected JSON body:
    {
        "date": "YYYY-MM-DD",
        "meal_type": "breakfast/lunch/dinner/snack",
        "calories": 500,
        "protein": 25,
        "carbs": 60,
        "fat": 20
    }
    """
    try:
        user_key = get_user_key(event)
        data = json.loads(event.get('body', '{}'))
        date = data.get('date')
        if not date:
            return response(400, "Date is required.")

        meal_id = str(uuid.uuid4())
        # Store meal log in the DynamoDB table with the user key
        meals_table.put_item(Item={
            'user': user_key,
            'date': date,
            'meal_id': meal_id,
            'meal_type': data.get('meal_type', 'unspecified'),
            'calories': data.get('calories', 0),
            'protein': data.get('protein', 0),
            'carbs': data.get('carbs', 0),
            'fat': data.get('fat', 0),
            'timestamp': datetime.utcnow().isoformat()
        })
        return response(200, f"Meal logged for {date}.")
    except ValueError as ve:
        return response(401, str(ve))
    except Exception as e:
        logger.error("Error in log_meal: %s", e, exc_info=True)
        return response(500, str(e))

def track_macros(event):
    """
    Expects a query parameter 'date'
    Returns aggregated macros for the day along with set goals.
    """
    try:
        user_key = get_user_key(event)
        params = event.get('queryStringParameters') or {}
        date = params.get('date')
        if not date:
            return response(400, "Date query parameter is required.")

        # Retrieve all meal logs for the specified user and date
        result = meals_table.query(
            KeyConditionExpression=Key('user').eq(user_key) & Key('date').eq(date)
        )
        meals = result.get('Items', [])

        # Aggregate macros from meal logs
        totals = {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0}
        for meal in meals:
            totals['calories'] += meal.get('calories', 0)
            totals['protein'] += meal.get('protein', 0)
            totals['carbs'] += meal.get('carbs', 0)
            totals['fat'] += meal.get('fat', 0)

        # Retrieve the goals for the user for the specified day
        goal_item = goals_table.get_item(Key={'user': user_key, 'date': date}).get('Item')
        goals = goal_item if goal_item else {}

        result_body = {
            'date': date,
            'goals': goals,
            'totals': totals,
            'meals_logged': len(meals)
        }
        return response(200, result_body)
    except ValueError as ve:
        return response(401, str(ve))
    except Exception as e:
        logger.error("Error in track_macros: %s", e, exc_info=True)
        return response(500, str(e))

def response(status_code, message):
    """Helper function to build a response."""
    return {
        'statusCode': status_code,
        'body': json.dumps(message, default=decimal_default),
        'headers': {
            'Content-Type': 'application/json'
        }
    }

def lambda_handler(event, context):
    """
    Main Lambda handler that routes the request based on the path and HTTP method.
    """
    path = event.get('path', '')
    http_method = event.get('httpMethod', '')

    if path == '/set-goals' and http_method == 'POST':
        return set_goals(event)
    elif path == '/log-meal' and http_method == 'POST':
        return log_meal(event)
    elif path == '/track-macros' and http_method == 'GET':
        return track_macros(event)
    else:
        return response(404, "Not Found")