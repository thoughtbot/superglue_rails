import MessagesIndex from "@views/messages/index.html.jsx";
import MessagesShow from "@views/messages/show.html.jsx";
import ProfileIndex from "@views/users/profiles/index.html.jsx";
import SectionIndex from "@views/messages/section.html.jsx"
// import your page component
// e.g import PostsEdit from '../views/posts/edit.html.jsx'

// Mapping between your props template to Component, you must add to this
// to register any new page level component you create. If you are using the
// scaffold, it will auto append the identifers for you.
//
// For example:
//
// const pageIdentifierToPageComponent =  {
//   'posts/new': PostNew
// };
//
//
// If you are using a build tool that supports globbing, you can automatically
// populate `pageIdentiferToPageComponent`. For example, if you are using vite,
// you can use the following snippet instead of manually importing.
//
// ```
// const pageIdentifierToPageComponent = {}
// const pages = import.meta.glob('../views/**/*.html.jsx', {eager: true})
//
// for (const key in pages) {
//   if (pages.hasOwnProperty(key)) {
//     const identifier = key.replace("../views/", "").split('.')[0];
//     pageIdentifierToPageComponent[identifier] = pages[key].default;
//   }
// }
// ```
//
const pageIdentifierToPageComponent = {
    'messages/index': MessagesIndex,
    'messages/show': MessagesShow,
    'users/profiles/index': ProfileIndex,
    'messages/section': SectionIndex,
};

export { pageIdentifierToPageComponent }
