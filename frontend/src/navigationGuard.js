function normalizeDestination(destination) {
  const url = new URL(destination, "http://gymproject.local");
  return `${url.pathname}${url.search}${url.hash}`;
}

export function createNavigationGuard() {
  let permittedDestination = null;

  return {
    allowNextNavigationTo(destination) {
      permittedDestination = normalizeDestination(destination);
    },

    shouldBlock({ currentLocation, nextLocation, hasUnsavedChanges, navigationLocked }) {
      const nextDestination = `${nextLocation.pathname}${nextLocation.search}${nextLocation.hash}`;
      const matchesPermit = permittedDestination === nextDestination;
      // A successful-save permit is single-use, including when another route
      // attempt happens first, so it cannot leak into a later manual navigation.
      permittedDestination = null;
      if (matchesPermit) return false;

      return (hasUnsavedChanges || navigationLocked)
        && currentLocation.pathname !== nextLocation.pathname;
    },
  };
}
