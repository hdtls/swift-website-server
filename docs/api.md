# Website API

- [User](#user)
- [Blog](#blog)
- [Industry](#industry)
- [Experience](#experience)
- [Education](#education)
- [Project](#project)
- [Skill](#skill)
- [Social Networking service](#social-networking-service)
- [Social Networking](#social-networking)

## User

### POST user

#### Resource URL

`http://localhost:8080/users`

#### Resource Information

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Content-Type            | JSON  |
| Requires authentication | false |

#### User Data Object

| Name      | Required | Description      | Value Type | Example |
| :-------- | :------- | :--------------- | :--------- | :------ |
| username  | true     | Account username | String     | example |
| password  | true     | Account password | String     | 111111  |
| firstName | true     | User first-name  | String     | xxx     |
| lastName  | true     | User last-name   | String     | xxx     |

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/users \
--header 'content-type: application/json' \
--data '{"username" : "example", "password" : "111111", "firstName" : "xxx", "lastName" : "xxx"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "accessToken": "gLPfwRrYAc9pIbTrBeoiIg==",
  "user": {
    "username": "example",
    "id": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
    "firstName": "xxx",
    "lastName": "xxx"
  }
}
```

### GET user with id

#### Resource URL

`GET http://localhost:8080/users/:id`

#### Resource Infomation

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Query Parameters

| Name         | Required | Default Value |
| :----------- | :------- | :------------ |
| incl_wrk_exp | false    | false         |
| incl_edu_exp | false    | false         |
| incl_sns     | false    | false         |
| incl_projs   | false    | false         |
| incl_skill   | false    | false         |
| incl_blog    | false    | false         |

#### Example Request

```shell
curl --url http://localhost:8080/users/42252245-FE4C-4C17-9FDE-2C21B6E5A92F?incl_projs=true
```

## Blog

### POST blog

#### Resource URL

`POST http://localhost:8080/blog`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Blog Data Object

| Name       | Required | Description                | Value Type    | Example                              |
| :--------- | :------- | :------------------------- | :------------ | :----------------------------------- |
| alias      | true     | Blog id alias              | String        | this-is-my-first-blog                |
| title      | true     | Blog title.                | String        | Blog Title                           |
| artworkUrl | false    | Blog background image url. | String        | http://localhost:8080/images/xxx.jpg |
| excerpt    | true     | Blog excerpt.              | String        | This is blog excerpt                 |
| tags       | false    | Blog tags.                 | Array<String> | [tag1, tag2]                         |
| content    | true     | Blog content.              | String        | This is blog content.                |

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/blog \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"alias": "this-is-my-firt-blog", "title": "Blog Title", "excerpt": "This is blog excerpt.", "tags": ["tag1", "tag2"], "content": "This is blog content."}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "excerpt": "This is blog excerpt.",
  "alias": "this-is-my-firt-blog",
  "content": "This is blog content.",
  "id": "D2D90F89-1F5F-4D5A-A8B1-3186F4A909E2",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "title": "Blog Title",
  "createAt": "2020-10-06T16:26:31Z",
  "tags": ["tag1", "tag2"],
  "updateAt": "2020-10-06T16:26:32Z"
}
```

### GET blog with id/alias

#### Resource URL

`GET http://localhost:8080/blog/:id`

#### Resource Infomation

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl --url http://localhost:8080/blog/D2D90F89-1F5F-4D5A-A8B1-3186F4A909E2
curl --url http://localhost:8080/blog/this-is-my-firt-blog
```

#### Example Response

`Status: 200 OK`

```json
{
  "excerpt": "This is blog excerpt.",
  "alias": "this-is-my-firt-blog",
  "content": "This is blog content.",
  "id": "D2D90F89-1F5F-4D5A-A8B1-3186F4A909E2",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "title": "Blog Title",
  "createAt": "2020-10-06T16:26:31Z",
  "tags": ["tag1", "tag2"],
  "updateAt": "2020-10-06T16:26:32Z"
}
```

### GET all blog

#### Resource URL

`GET http://localhost:8080/blog`

#### Resource Infomation

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Example Request

```shell
curl --url http://localhost:8080/blog
```

#### Example Response

`Status: 200 OK`

```json
[
  {
    "excerpt": "This is blog excerpt.",
    "alias": "this-is-my-firt-blog",
    "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
    "id": "D2D90F89-1F5F-4D5A-A8B1-3186F4A909E2",
    "title": "Blog Title",
    "createAt": "2020-10-06T16:26:31Z",
    "tags": ["tag1", "tag2"],
    "updateAt": "2020-10-06T16:26:32Z"
  }
]
```

### PUT blog with id/alias

#### Resource URL

`PUT http://localhost:8080/blog/:id`

#### Resource Infomation

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Blog Data Object

| Name       | Required | Description                | Value Type    | Example                         |
| :--------- | :------- | :------------------------- | :------------ | :------------------------------ |
| alias      | true     | Blog id alias              | String        | this-is-my-first-blog           |
| title      | true     | Blog title.                | String        | Blog Title                      |
| artworkUrl | false    | Blog background image url. | String        | http://localhost/images/xxx.jpg |
| excerpt    | true     | Blog excerpt.              | String        | This is blog excerpt            |
| tags       | false    | Blog tags.                 | Array<String> | [tag1, tag2]                    |
| content    | true     | Blog content.              | String        | This is blog content.           |

#### Example Request

```shell
curl \
--request PUT \
--url http://localhost:8080/blog/D2D90F89-1F5F-4D5A-A8B1-3186F4A909E2 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"alias": "this-is-my-firt-blog", "title": "Blog Title", "excerpt": "This is blog excerpt.", "tags": ["tag1", "tag2"], "content": "This is blog content."}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "excerpt": "This is blog excerpt.",
  "alias": "this-is-my-firt-blog",
  "content": "This is blog content.",
  "id": "D2D90F89-1F5F-4D5A-A8B1-3186F4A909E2",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "title": "Blog Title",
  "createAt": "2020-10-06T16:26:31Z",
  "tags": ["tag1", "tag2"],
  "updateAt": "2020-10-06T16:32:41Z"
}
```

### DELETE blog with id/alias

#### Resource URL

`DELETE http://localhost:8080/blog/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl \
--request DELETE \
--url http://localhost:8080/blog/D2D90F89-1F5F-4D5A-A8B1-3186F4A909E2 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg=='
```

#### Example Response

`Status: 200 OK`

## Industry

### POST industry

#### Resource URL

`POST http://localhost:8080/industries`

#### Resource Infomation

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Industry Data Object

| Name  | Required | Description     | Value Type | Example        |
| :---- | :------- | :-------------- | :--------- | :------------- |
| title | true     | Industry title. | String     | Industry Title |

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/industries \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"title": "Industry Title"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "C177593D-0EA4-41B6-866F-24E155AEC86C",
  "title": "Industry Title"
}
```

### GET industry with id

#### Resource URL

`http://localhost:8080/industries/:id`

#### Resource Infomation

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl --url http://localhost:8080/industries/C177593D-0EA4-41B6-866F-24E155AEC86C
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "C177593D-0EA4-41B6-866F-24E155AEC86C",
  "title": "Industry Title"
}
```

### PUT industry with id

#### Resource URL

`PUT http://localhost:8080/industries/:id`

#### Resource Infomation

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Industry Data Object

| Name  | Required | Description     | Value Type | Example            |
| :---- | :------- | :-------------- | :--------- | :----------------- |
| title | true     | Industry title. | String     | New Industry Title |

#### Example Request

```shell
curl \
--request PUT \
--url http://localhost:8080/industries/C177593D-0EA4-41B6-866F-24E155AEC86C \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"title": "New Industry Title"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "C177593D-0EA4-41B6-866F-24E155AEC86C",
  "title": "New Industry Title"
}
```

### DELETE industry with id

#### Resource URL

`DELETE http://localhost:8080/industries/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl \
--request DELETE \
--url http://localhost:8080/industries/C177593D-0EA4-41B6-866F-24E155AEC86C \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg=='
```

#### Example Response

`Status: 200 OK`

## Experience

### POST experience

#### Resource URL

`http://localhost:8080/experiences`

#### Resource Infomation

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Experence Data Object

| Name             | Required | Description                                      | Value Type          | Example    |
| :--------------- | :------- | :----------------------------------------------- | :------------------ | :--------- |
| title            | true     | title                                            | String              | Engineer   |
| companyName      | true     | Company name.                                    | String              | xxx        |
| location         | true     | Work location.                                   | String              | xxx        |
| startDate        | true     | Work start date.                                 | String              | 2010-10    |
| endDate          | true     | Work end date.                                   | String              | 2011-10    |
| headline         | false    | Work headline.                                   | String              | headline.  |
| responsibilities | false    | Work responsibilities                            | Array<String>       | [xxx, xxx] |
| media            | false    | Experience media.                                | String              | xxx        |
| industries       | true     | Industries of work, require id for each industry | [[String : String]] | [{id:xxx}] |

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/experiences \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"title": "Engineer", "companyName": "xxx", "location": "xxx", "startDate": "2010-10", "endDate": "2011-10", "headline": "headline.", "responsibilities": ["xxx", "xxx"], "media": "xxx", "industries": [{"id": "C177593D-0EA4-41B6-866F-24E155AEC86C"}]}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "location": "xxx",
  "responsibilities": ["xxx", "xxx"],
  "endDate": "2011-10",
  "id": "3F4985F9-291F-4A82-B685-F74BAC5102FC",
  "startDate": "2010-10",
  "title": "Engineer",
  "media": "xxx",
  "companyName": "xxx",
  "industries": [
    {
      "id": "C177593D-0EA4-41B6-866F-24E155AEC86C",
      "title": "New Industry Title"
    }
  ],
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "headline": "headline."
}
```

### GET experience with id

#### Resource URL

`http://localhost:8080/experiences/:id`

#### Resource Infomation

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl --url http://localhost:8080/experiences/3F4985F9-291F-4A82-B685-F74BAC5102FC
```

#### Example Response

`Status: 200 OK`

```json
{
  "location": "xxx",
  "responsibilities": ["xxx", "xxx"],
  "endDate": "2011-10",
  "id": "3F4985F9-291F-4A82-B685-F74BAC5102FC",
  "startDate": "2010-10",
  "title": "Engineer",
  "media": "xxx",
  "companyName": "xxx",
  "industries": [
    {
      "id": "C177593D-0EA4-41B6-866F-24E155AEC86C",
      "title": "New Industry Title"
    }
  ],
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "headline": "headline."
}
```

### PUT experience with id

#### Resource URL

`PUT http://localhost:8080/experiences/:id`

#### Resource Infomation

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Experence Data Object

| Name             | Required | Description                                      | Value Type          | Example    |
| :--------------- | :------- | :----------------------------------------------- | :------------------ | :--------- |
| title            | true     | title                                            | String              | Engineer   |
| companyName      | true     | Company name.                                    | String              | xxx        |
| location         | true     | Work location.                                   | String              | xxx        |
| startDate        | true     | Work start date.                                 | String              | 2010-10    |
| endDate          | true     | Work end date.                                   | String              | 2011-10    |
| headline         | false    | Work headline.                                   | String              | headline.  |
| responsibilities | false    | Work responsibilities                            | Array<String>       | [xxx, xxx] |
| media            | false    | Experience media.                                | String              | xxx        |
| industries       | true     | Industries of work, require id for each industry | [[String : String]] | [{id:xxx}] |

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/experiences \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"title": "Software Engineer", "companyName": "xxx", "location": "xxx", "startDate": "2010-10", "endDate": "2011-10", "headline": "headline.", "responsibilities": ["xxx", "xxx"], "media": "xxx", "industries": [{"id": "C177593D-0EA4-41B6-866F-24E155AEC86C"}]}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "location": "xxx",
  "responsibilities": ["xxx", "xxx"],
  "endDate": "2011-10",
  "id": "AA2AD105-3FC3-4E65-8E5F-AE99BA5DD6E0",
  "startDate": "2010-10",
  "title": "Software Engineer",
  "media": "xxx",
  "companyName": "xxx",
  "industries": [
    {
      "id": "C177593D-0EA4-41B6-866F-24E155AEC86C",
      "title": "New Industry Title"
    }
  ],
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "headline": "headline."
}
```

### DELETE experience with id

#### Resource URL

`DELETE http://localhost:8080/experiences/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl \
--request DELETE \
--url http://localhost:8080/experiences/AA2AD105-3FC3-4E65-8E5F-AE99BA5DD6E0 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg=='
```

#### Example Response

`Status: 200 OK`

## Education

### POST education experience

#### Resource URL

`POST http://localhost:8080/education`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Education Data Object

| Name            | Required | Description                          | Value Type    | Example                            |
| :-------------- | :------- | :----------------------------------- | :------------ | :--------------------------------- |
| school          | true     | School name                          | String        | School Name                        |
| degree          | true     | Degree of this education experience. | String        | degree                             |
| field           | true     | Field                                | String        | field                              |
| startYear       | false    | The year this education start with.  | String        | 2010                               |
| endYear         | false    | Graduate year                        | String        | 2014                               |
| grade           | false    | Grade                                | String        | grade                              |
| activities      | false    | Activities                           | Array<String> | [activity1, activity2]             |
| accomplishments | false    |                                      | Array<String> | [accomplishment1, accomplishment2] |
| media           | false    |                                      | String        | media                              |

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/education \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"school": "School Name", "degree": "degree", "field": "field", "startYear": "2010", "endYear": "2014", "grade": "grade", "activities": ["activity1", "activity2"], "accomplishments" : ["accomplishment1", "accomplishment2"], "media": "media"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "school": "School Name",
  "degree": "degree",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "id": "DD120F37-7C79-4813-A981-2E4AFA0280D1",
  "grade": "grade",
  "startYear": "2010",
  "field": "field",
  "endYear": "2014",
  "accomplishments": ["accomplishment1", "accomplishment2"],
  "media": "media",
  "activities": ["activity1", "activity2"]
}
```

### GET education experience with id

#### Resource URL

`GET http://localhost:8080/education/:id`

#### Resource Infomation

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl --url http://localhost:8080/education/DD120F37-7C79-4813-A981-2E4AFA0280D1
```

#### Example Response

`Status: 200 OK`

```json
{
  "school": "School Name",
  "degree": "degree",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "id": "DD120F37-7C79-4813-A981-2E4AFA0280D1",
  "grade": "grade",
  "startYear": "2010",
  "field": "field",
  "endYear": "2014",
  "accomplishments": ["accomplishment1", "accomplishment2"],
  "media": "media",
  "activities": ["activity1", "activity2"]
}
```

### PUT education experience with id

#### Resource URL

`PUT http://localhost:8080/education/:id`

#### Resource Infomation

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Education Data Object

| Name            | Required | Description                          | Value Type    | Example                            |
| :-------------- | :------- | :----------------------------------- | :------------ | :--------------------------------- |
| school          | true     | School name                          | String        | School Name                        |
| degree          | true     | Degree of this education experience. | String        | degree                             |
| field           | true     | Field                                | String        | field                              |
| startYear       | false    | The year this education start with.  | String        | 2010                               |
| endYear         | false    | Graduate year                        | String        | 2014                               |
| grade           | false    | Grade                                | String        | grade                              |
| activities      | false    | Activities                           | Array<String> | [activity1, activity2]             |
| accomplishments | false    |                                      | Array<String> | [accomplishment1, accomplishment2] |
| media           | false    |                                      | String        | media                              |

#### Example Request

```shell
curl \
--request PUT \
--url http://localhost:8080/education/DD120F37-7C79-4813-A981-2E4AFA0280D1 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"school": "School Name", "degree": "degree", "field": "field", "startYear": "2014", "endYear": "2018", "grade": "grade", "activities": ["activity1", "activity2"], "accomplishments" : ["accomplishment1", "accomplishment2"], "media": "media"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "school": "School Name",
  "degree": "degree",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "id": "DD120F37-7C79-4813-A981-2E4AFA0280D1",
  "grade": "grade",
  "startYear": "2014",
  "field": "field",
  "endYear": "2018",
  "accomplishments": ["accomplishment1", "accomplishment2"],
  "media": "media",
  "activities": ["activity1", "activity2"]
}
```

### DELETE education experience with id

#### Resource URL

`DELETE http://localhost:8080/education/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl \
--request DELETE \
--url http://localhost:8080/education/DD120F37-7C79-4813-A981-2E4AFA0280D1 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg=='
```

#### Example Response

`Status: 200 OK`

## Project

### POST project

#### Resource URL

`POST http://localhost:8080/projects`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Project Data Object

| Name               | Required | Description                                  | Value Type    | Example                                                                                      |
| :----------------- | :------- | :------------------------------------------- | :------------ | :------------------------------------------------------------------------------------------- |
| name               | true     | Project name                                 | String        | Project Name                                                                                 |
| note               | false    | Project note                                 | String        | note                                                                                         |
| genres             | false    | Project genres                               | Array<String> | [genres1, genres2]                                                                           |
| summary            | true     | Project summary                              | String        | Project summary                                                                              |
| artworkUrl         | false    | Project artwork url                          | String        | http://localhost:8080/x.artwork.jpg                                                          |
| backgroundImageUrl | false    | Project background image url                 | String        | http://localhost:8080/x.backgroundimageurl.jpg                                               |
| promoImageUrl      | false    | Promotion image url                          | String        | http://localhost:8080/x.promotion1.jpg                                                       |
| screenshotUrls     | false    | Project screenshot image urls                | Array<String> | [http://localhost:8080/x.screenshot1.jpg, http://localhost:8080/x.screenshot2.jpg]           |
| padScreenshotUrls  | false    | Project iPad screenshot image urls           | Array<String> | [http://localhost:8080/x.ipad.screenshot1.jpg, http://localhost:8080/x.ipad.screenshot2.jpg] |
| kind               | true     | Kind of Project. seealso `ProjKind`          | String        | app                                                                                          |
| visibility         | true     | Project visibility. seealse `ProjVisibility` | String        | public                                                                                       |
| trackViewUrl       | false    | Project track view url                       | String        | http://proj.track/1                                                                          |
| trackId            | false    | Project track id                             | String        | 1                                                                                            |
| startDate          | true     | Project start date                           | String        | 2010-10                                                                                      |
| endDate            | true     | Project end date                             | String        | 2010-11                                                                                      |

##### Project Kind

```swift
enum ProjKind: String {
case app
case website
case repositry
}
```

##### Project Visibility

```swift
enum ProjVisibility: String {
case `private`
case `public`
}
```

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/projects \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"name": "Project name", "note": "note", "genres": ["genres1", "genres2"], "summary": "Project summary", "artworkUrl": "http://localhost:8080/x.artwork.jpg", "backgroundImageUrl": "http://localhost:8080/x.backgroundimageurl.jpg", "promoImageUrl": "http://localhost:8080/x.promotion1.jpg", "screenshotUrls": ["http://localhost:8080/x.screenshot1.jpg", "http://localhost:8080/x.screenshot2.jpg"], "padScreenshotUrls" : ["http://localhost:8080/x.ipad.screenshot1.jpg", "http://localhost:8080/x.ipad.screenshot2.jpg"], "kind": "app", "visibility":"public", "trackViewUrl": "http://proj.track/1", "trackId": "1", "startDate": "2010-10", "endDate": "2010-11"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "F670926F-C300-4C35-9599-1B351F5A4DA4",
  "padScreenshotUrls": [
    "http://localhost:8080/x.ipad.screenshot1.jpg",
    "http://localhost:8080/x.ipad.screenshot2.jpg"
  ],
  "promoImageUrl": "http://localhost:8080/x.promotion1.jpg",
  "trackViewUrl": "http://proj.track/1",
  "note": "note",
  "trackId": "1",
  "startDate": "2010-10",
  "endDate": "2010-11",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "summary": "Project summary",
  "visibility": "public",
  "artworkUrl": "http://localhost:8080/x.artwork.jpg",
  "genres": ["genres1", "genres2"],
  "screenshotUrls": [
    "http://localhost:8080/x.screenshot1.jpg",
    "http://localhost:8080/x.screenshot2.jpg"
  ],
  "kind": "app",
  "name": "Project name",
  "backgroundImageUrl": "http://localhost:8080/x.backgroundimageurl.jpg"
}
```

### GET project with id

#### Resource URL

`GET http://localhost:8080/project/:id`

#### Resource Infomation

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl --url http://localhost:8080/projects/F670926F-C300-4C35-9599-1B351F5A4DA4
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "F670926F-C300-4C35-9599-1B351F5A4DA4",
  "padScreenshotUrls": [
    "http://localhost:8080/x.ipad.screenshot1.jpg",
    "http://localhost:8080/x.ipad.screenshot2.jpg"
  ],
  "promoImageUrl": "http://localhost:8080/x.promotion1.jpg",
  "trackViewUrl": "http://proj.track/1",
  "note": "note",
  "trackId": "1",
  "startDate": "2010-10",
  "endDate": "2010-11",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "summary": "Project summary",
  "visibility": "public",
  "artworkUrl": "http://localhost:8080/x.artwork.jpg",
  "genres": ["genres1", "genres2"],
  "screenshotUrls": [
    "http://localhost:8080/x.screenshot1.jpg",
    "http://localhost:8080/x.screenshot2.jpg"
  ],
  "kind": "app",
  "name": "Project name",
  "backgroundImageUrl": "http://localhost:8080/x.backgroundimageurl.jpg"
}
```

### PUT project with id

#### Resource URL

`PUT http://localhost:8080/projects/:id`

#### Resource Infomation

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Project Data Object

seealso [Project Data Object For Post Request](#project-data-object)

#### Example Request

```shell
curl \
--request PUT \
--url http://localhost:8080/projects/F670926F-C300-4C35-9599-1B351F5A4DA4 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"name": "Project new name", "note": "note", "genres": ["genres1", "genres2"], "summary": "Project summary", "artworkUrl": "http://localhost:8080/x.artwork.jpg", "backgroundImageUrl": "http://localhost:8080/x.backgroundimageurl.jpg", "promoImageUrl": "http://localhost:8080/x.promotion1.jpg", "screenshotUrls": ["http://localhost:8080/x.screenshot1.jpg", "http://localhost:8080/x.screenshot2.jpg"], "padScreenshotUrls" : ["http://localhost:8080/x.ipad.screenshot1.jpg", "http://localhost:8080/x.ipad.screenshot2.jpg"], "kind": "app", "visibility":"public", "trackViewUrl": "http://proj.track/1", "trackId": "1", "startDate": "2010-10", "endDate": "2010-11"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "F670926F-C300-4C35-9599-1B351F5A4DA4",
  "padScreenshotUrls": [
    "http://localhost:8080/x.ipad.screenshot1.jpg",
    "http://localhost:8080/x.ipad.screenshot2.jpg"
  ],
  "promoImageUrl": "http://localhost:8080/x.promotion1.jpg",
  "trackViewUrl": "http://proj.track/1",
  "note": "note",
  "trackId": "1",
  "startDate": "2010-10",
  "endDate": "2010-11",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "summary": "Project summary",
  "visibility": "public",
  "artworkUrl": "http://localhost:8080/x.artwork.jpg",
  "genres": ["genres1", "genres2"],
  "screenshotUrls": [
    "http://localhost:8080/x.screenshot1.jpg",
    "http://localhost:8080/x.screenshot2.jpg"
  ],
  "kind": "app",
  "name": "Project new name",
  "backgroundImageUrl": "http://localhost:8080/x.backgroundimageurl.jpg"
}
```

### DELETE project with id

#### Resource URL

`DELETE http://localhost:8080/projects/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl \
--request DELETE \
--url http://localhost:8080/projects/F670926F-C300-4C35-9599-1B351F5A4DA4 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg=='
```

#### Example Response

`Status: 200 OK`

## Skill

### POST skill

#### Resource URL

`POST http://localhost:8080/skills`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Skill Data Object

| Name        | Required | Description        | Value Type    | Example    |
| :---------- | :------- | :----------------- | :------------ | :--------- |
| profesional | true     | Profesional skills | Array<String> | [xxx, xxx] |
| workflow    | false    | Workflow skills    | Array<String> | [xxx, xxx] |

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/skills \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"profesional": ["xxx", "xxx"], "workflow": ["xxx", "xxx"]}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "32C2D596-3D76-4F35-B82E-61257B895A83",
  "profesional": ["xxx", "xxx"],
  "workflow": ["xxx", "xxx"]
}
```

### GET skill with id

#### Resource URL

`GET http://localhost:8080/skills/:id`

#### Resource Information

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl --url http://localhost:8080/skills/32C2D596-3D76-4F35-B82E-61257B895A83
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "32C2D596-3D76-4F35-B82E-61257B895A83",
  "profesional": ["xxx", "xxx"],
  "workflow": ["xxx", "xxx"]
}
```

### PUT skill

#### Resource URL

`PUT http://localhost:8080/skills/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Skill Data Object

| Name        | Required | Description        | Value Type    | Example    |
| :---------- | :------- | :----------------- | :------------ | :--------- |
| profesional | true     | Profesional skills | Array<String> | [xxx, xxx] |
| workflow    | false    | Workflow skills    | Array<String> | [xxx, xxx] |

#### Example Request

```shell
curl \
--request PUT \
--url http://localhost:8080/skills/32C2D596-3D76-4F35-B82E-61257B895A83 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"profesional": ["profesional skill 1", "xxx"], "workflow": ["xxx", "xxx"]}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "32C2D596-3D76-4F35-B82E-61257B895A83",
  "profesional": ["profesional skill 1", "xxx"],
  "workflow": ["xxx", "xxx"]
}
```

### DELETE skill

#### Resource URL

`DELETE http://localhost:8080/skills/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl \
--request DELETE \
--url http://localhost:8080/skills/32C2D596-3D76-4F35-B82E-61257B895A83 \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg=='
```

#### Example Response

`Status: 200 OK`

## Social Networking Service

### POST service

#### Resource URL

`POST http://localhost:8080/social_networking/services`

#### Resource Information

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Content-Type            | JSON  |
| Requires authentication | false |

#### Service Data Object

| Name | Required | Description                    | Value Type                                 | Example |
| :--- | :------- | :----------------------------- | :----------------------------------------- | :------ |
| type | true     | Social networking service type | seealso `ServiceType` for more information | Twitter |

##### ServiceType

```swift
enum ServiceType: String {
case facebook = "Facebook"
case youTube = "YouTube"
case twitter = "Twitter"
case whatsApp = "WhatsApp"
case messenger = "Facebook Messenger"
case wechat = "WeChat"
case instagram = "Instagram"
case tikTok = "TikTok"
case qq = "QQ"
case qzone = "Qzone"
case weibo = "Sina Weibo"
case reddit = "Reddit"
case kuaishou = "Kuaishou"
case snapchat = "Snapchat"
case pinterest = "Pinterest"
case tieba = "Baidu Tieba"
case linkedIn = "LinkedIn"
case viber = "Viber"
case discord = "Discord"
case githup = "Github"
case stackOverflow = "StackOverflow"
case mail = "Mail"
case website = "Website"
case undefined
}
```

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/social_networking/services \
--header 'content-type: application/json' \
--data '{"type": "Twitter"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "0CEE62BC-79D8-4FC8-9486-CC139583C915",
  "type": "Twitter"
}
```

### GET service

#### Resource URL

`GET http://localhost:8080/social_networking/services/:id`

#### Resource Information

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl --url http://localhost:8080/social_networking/services/0CEE62BC-79D8-4FC8-9486-CC139583C915
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "0CEE62BC-79D8-4FC8-9486-CC139583C915",
  "type": "Twitter"
}
```

### PUT service

#### Resource URL

`PUT http://localhost:8080/social_networking/services/:id`

#### Resource Information

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Content-Type            | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Service Data Object

seealso [Service Data Object For Post Request](#service-data-object)

#### Example Request

```shell
curl \
--request PUT \
--url http://localhost:8080/social_networking/services/0CEE62BC-79D8-4FC8-9486-CC139583C915 \
--header 'content-type: application/json' \
--data '{"type": "Facebook"}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "BD267D7F-C49D-45D6-8015-5F1B5D6CA421",
  "type": "Facebook"
}
```

### DELETE service

#### Resource URL

`DELETE http://localhost:8080/social_networking/services/:id`

#### Resource Information

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl \
--request DELETE \
--url http://localhost:8080/social_networking/services/0CEE62BC-79D8-4FC8-9486-CC139583C915
```

#### Example Response

`Status: 200 OK`

## Social Networking

### POST social networking

#### Resource URL

`POST http://localhost:8080/social_networking`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Social Networking Data Object

| Name    | Required | Description                                               | Value Type          | Example                                        |
| :------ | :------- | :-------------------------------------------------------- | :------------------ | :--------------------------------------------- |
| url     | true     | Social networking reference url                           | String              | https://twitter.com/xxx                        |
| service | true     | SocialNetworkingService object. only id field is required | `[String : String]` | {"id": "0CEE62BC-79D8-4FC8-9486-CC139583C915"} |

#### Example Request

```shell
curl \
--request POST \
--url http://localhost:8080/social_networking \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"url": "https://twitter.com/xxx", "service": {"id": "0CEE62BC-79D8-4FC8-9486-CC139583C915"}}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "4304A79A-41EE-402F-8AF2-3B55B02499BD",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "url": "https://twitter.com/xxx",
  "service": {
    "id": "0CEE62BC-79D8-4FC8-9486-CC139583C915",
    "type": "Twitter"
  }
}
```

### GET social networking with id

#### Resource URL

`GET http://localhost:8080/social_networking/:id`

#### Resource Information

|                         |       |
| :---------------------- | :---- |
| Response formats        | JSON  |
| Requires authentication | false |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl --url http://localhost:8080/social_networking/4304A79A-41EE-402F-8AF2-3B55B02499BD
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "4304A79A-41EE-402F-8AF2-3B55B02499BD",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "url": "https://twitter.com/xxx",
  "service": {
    "id": "0CEE62BC-79D8-4FC8-9486-CC139583C915",
    "type": "Twitter"
  }
}
```

### PUT social networking with id

#### Resource URL

`PUT http://localhost:8080/social_networking/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Content-Type            | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Social Networking Data Object

| Name    | Required | Description                                               | Value Type          | Example                                        |
| :------ | :------- | :-------------------------------------------------------- | :------------------ | :--------------------------------------------- |
| url     | true     | Social networking reference url                           | String              | "https://twitter.com/blackjack"                |
| service | true     | SocialNetworkingService object. only id field is required | `[String : String]` | {"id": "0CEE62BC-79D8-4FC8-9486-CC139583C915"} |

#### Example Request

```shell
curl \
--request PUT \
--url http://localhost:8080/social_networking/4304A79A-41EE-402F-8AF2-3B55B02499BD \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg==' \
--header 'content-type: application/json' \
--data '{"url": "blackjack", "service": {"id": "0CEE62BC-79D8-4FC8-9486-CC139583C915"}}'
```

#### Example Response

`Status: 200 OK`

```json
{
  "id": "4304A79A-41EE-402F-8AF2-3B55B02499BD",
  "userId": "42252245-FE4C-4C17-9FDE-2C21B6E5A92F",
  "url": "blackjack",
  "service": {
    "id": "0CEE62BC-79D8-4FC8-9486-CC139583C915",
    "type": "Twitter"
  }
}
```

### DELETE social networking with id

#### Resource URL

`DELETE http://localhost:8080/social_networking/:id`

#### Resource Information

|                         |      |
| :---------------------- | :--- |
| Response formats        | JSON |
| Requires authentication | true |

#### Parameters

| Name | Required |
| :--- | :------- |
| id   | true     |

#### Example Request

```shell
curl \
--request DELETE \
--url http://localhost:8080/social_networking/4304A79A-41EE-402F-8AF2-3B55B02499BD \
--header 'Authorization: Bearer gLPfwRrYAc9pIbTrBeoiIg=='
```

#### Example Response

`Status: 200 OK`
