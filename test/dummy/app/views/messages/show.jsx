import React from 'react'
import { useContent } from '@thoughtbot/superglue'
import { SubmitButton, Form } from '@javascript/components'

export default function MessagesShow() {
  const content = useContent()
  const {form, extras, inputs} = content.updateMessageForm


  return (
    <div>
      <h1> Message Show</h1>
      <div>
        {content.message.body}
      </div>

      <Form {...form} extras={extras} data-sg-visit={true}>
        <SubmitButton {...inputs.submit}/>
      </Form>
    </div>
  )
}
