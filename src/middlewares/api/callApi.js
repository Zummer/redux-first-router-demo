import queryString from 'query-string';
import {apiRest} from '../../utils';

const API_PREFIX = '/api';

export const callApi = async (
  endpoint,
  method,
  token,
  queryParams,
  requestBody
) => {
  let fullUrl = apiRest + API_PREFIX + endpoint;

  if (queryParams && typeof queryParams === 'object') {
    if (fullUrl.indexOf('/?') === -1) {
      fullUrl += `?${queryString.stringify(queryParams)}`;
    } else {
      fullUrl += `&${queryString.stringify(queryParams)}`;
    }
  }

  const requestOptions = {
    method,
    credentials: 'same-origin',
    headers: {
      Accept: 'application/json',
    },
  };

  if (requestBody) {
    requestOptions.headers['Content-Type'] = 'application/json';
    requestOptions.body = JSON.stringify(requestBody);
  }

  if (token) {
    requestOptions.headers.Authorization = `Bearer ${token}`;
  }

  const response = await fetch(fullUrl, requestOptions);
  const data = await response.json();

  if (!response.ok) {
    throw data;
  } else {
    return data;
  }
};

export default callApi;
