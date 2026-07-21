import React from 'react'
import { useContent, useFragment, toFragmentRef, useStreamSource } from '@thoughtbot/superglue'

export default function ProfileIndex() {
  const { streamFromMessages} = useContent()
  const profile = useFragment(toFragmentRef('profile'), {optional: true})

  useStreamSource(streamFromMessages)

  return (
    <div>
      <h1>Users::Profiles</h1>

      <div id="users_profiles">
        {profile?.name}
      </div>
    </div>
  )
}
