import os
import json
import boto3
import uuid
import logging
from datetime import datetime
from boto3.dynamodb.conditions import Key  # Direct import for cleaner usage

# Set up basic logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Retrieve DynamoDB table names from environment variables
GOALS_TABLE_NAME = os.environ.get('GOALS_TABLE_NAME', 'default-DietGoals')
MEALS_TABLE_NAME = os.environ.get('MEALS_TABLE_NAME', 'default-MealLogs')

# Initialize DynamoDB resource using dynamic table names
dynamodb = boto3.resource('dynamodb')
goals_table = dynamodb.Table(GOALS_TABLE_NAME)
meals_table = dynamodb.Table(MEALS_TABLE_NAME)


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
        data = json.loads(event.get('body', '{}'))
        date = data.get('date')
        if not date:
            return response(400, "Date is required.")

        # Store the daily goals in the DynamoDB table
        goals_table.put_item(Item={
            'date': date,
            'calories': data.get('calories', 0),
            'protein': data.get('protein', 0),
            'carbs': data.get('carbs', 0),
            'fat': data.get('fat', 0)
        })
        return response(200, f"Goals for {date} set successfully.")
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
        data = json.loads(event.get('body', '{}'))
        date = data.get('date')
        if not date:
            return response(400, "Date is required.")

        meal_id = str(uuid.uuid4())
        # Store meal log in the DynamoDB table
        meals_table.put_item(Item={
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
    except Exception as e:
        logger.error("Error in log_meal: %s", e, exc_info=True)
        return response(500, str(e))


def track_macros(event):
    """
    Expects a query parameter 'date'
    Returns aggregated macros for the day along with set goals.
    """
    try:
        params = event.get('queryStringParameters') or {}
        date = params.get('date')
        if not date:
            return response(400, "Date query parameter is required.")

        # Retrieve all meal logs for the specified date
        result = meals_table.query(
            KeyConditionExpression=Key('date').eq(date)
        )
        meals = result.get('Items', [])

        # Aggregate macros from meal logs
        totals = {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0}
        for meal in meals:
            totals['calories'] += meal.get('calories', 0)
            totals['protein'] += meal.get('protein', 0)
            totals['carbs'] += meal.get('carbs', 0)
            totals['fat'] += meal.get('fat', 0)

        # Retrieve the goals for the day
        goal_item = goals_table.get_item(Key={'date': date}).get('Item')
        goals = goal_item if goal_item else {}

        result_body = {
            'date': date,
            'goals': goals,
            'totals': totals,
            'meals_logged': len(meals)
        }
        return response(200, result_body)
    except Exception as e:
        logger.error("Error in track_macros: %s", e, exc_info=True)
        return response(500, str(e))


def response(status_code, message):
    """Helper function to build a response."""
    return {
        'statusCode': status_code,
        'body': json.dumps(message),
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