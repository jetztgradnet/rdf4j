/*******************************************************************************
 * Copyright (c) 2021 Eclipse RDF4J contributors.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Distribution License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/org/documents/edl-v10.php.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *******************************************************************************/

package org.eclipse.rdf4j.spring.support;

import java.util.UUID;

import org.eclipse.rdf4j.model.IRI;

/**
 * @since 4.0.0
 * @author Florian Kleedorfer
 */
public class DefaultUUIDSource implements UUIDSource {
	@Override
	public IRI nextUUID() {
		return toURNUUID(UUID.randomUUID().toString());
	}
}
